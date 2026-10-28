//
//  QFHUD.m
//

#import "QFHUD.h"

#import "QFPrivate.h"
#import "UIApplication+Private.h"
#import "UIWindow+Private.h"
#import "UIEventDispatcher.h"
#import "UIEventFetcher.h"
#import "SBSAccessibilityWindowHostingController.h"
#import "QFTouch.h"
#import "QFRowView.h"
#import "QFPanelView.h"
#import "QFMetrics.h"
#import "QFPrefs.h"

#import <spawn.h>
#import <signal.h>
#import <sys/wait.h>
#import <unistd.h>
#import <stdlib.h>
#import <mach-o/dyld.h>
#import <notify.h>

extern char **environ;

#define QF_PID_PATH_C "/var/mobile/Library/Caches/com.qfmonitor.hud.pid"
#define QF_PID_PATH   @"/var/mobile/Library/Caches/com.qfmonitor.hud.pid"
#define QF_NOTIFY_LAUNCHED "com.qfmonitor.notification.hud.launched"

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t * __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t * __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t * __restrict, uid_t);


#pragma mark - FrontBoard 方向观察(私有类, 运行时查找)

@protocol QFOrientationUpdate <NSObject>
- (long long)orientation;
- (double)duration;
@end

@protocol QFOrientationObserver <NSObject>
- (void)setHandler:(void (^)(id update))handler;
- (void)invalidate;
@end

#pragma mark - 窗口

@interface QFHUDWindow : UIWindow
@end

@implementation QFHUDWindow

+ (BOOL)_isSystemWindow { return YES; }
- (BOOL)_isWindowServerHostingManaged { return NO; }
- (BOOL)_ignoresHitTest { return [QFPrefs shared].passthrough; }
- (BOOL)_isSecure { return YES; }
- (BOOL)_shouldCreateContextAsSecure { return YES; }

@end

#pragma mark - 控制器

@interface QFHUDController () <QFRowViewDelegate, QFPanelViewDelegate>
@property (nonatomic, strong) QFRowView   *rowView;
@property (nonatomic, strong) QFPanelView *panelView;
@property (nonatomic, strong) NSTimer     *timer;
@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, strong) id            orientationObserver;
@end

@implementation QFHUDController

- (void)viewDidLoad {
    [super viewDidLoad];

    QFLog(@"QFHUDController viewDidLoad, view.bounds=%@", NSStringFromCGRect(self.view.bounds));
    self.view.backgroundColor = [UIColor clearColor];
    self.view.userInteractionEnabled = YES;

    _rowView = [[QFRowView alloc] initWithFrame:CGRectZero];
    _rowView.delegate = self;
    [self.view addSubview:_rowView];

    [self setupOrientationObserver];

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(tick)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    QFLog(@"QFHUDController viewDidAppear, rowView.frame=%@ window=%@",
          NSStringFromCGRect(self.rowView.frame), self.view.window);
    [QFTouchBridge install];
    notify_post(QF_NOTIFY_LAUNCHED);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutRow];
}

- (void)tick {
    [[QFMetrics shared] sampleAll];
    if ([[QFPrefs shared] reloadIfChanged]) {
        [self.rowView applyPrefs];
        [self layoutRow];
    }
    [self.rowView refreshText];
    if (self.panelView) [self.panelView refreshPreview];
}

#pragma mark - 位置

- (void)layoutRow {
    QFPrefs *p = [QFPrefs shared];
    CGFloat W = CGRectGetWidth(self.view.bounds);
    CGFloat H = CGRectGetHeight(self.view.bounds);
    if (W <= 0 || H <= 0) return;

    CGSize s = self.rowView.bounds.size;
    CGFloat x = p.posX * W;
    CGFloat y = p.posY * H;
    if (s.width > 0) {
        x = MAX(s.width / 2.0, MIN(W - s.width / 2.0, x));
    }
    if (s.height > 0) {
        y = MAX(s.height / 2.0, MIN(H - s.height / 2.0, y));
    }
    self.rowView.center = CGPointMake(x, y);
}

#pragma mark - 屏幕旋转

- (void)setupOrientationObserver {
    Class obsCls = objc_getClass("FBSOrientationObserver");
    if (!obsCls) return;
    id obs = [[obsCls alloc] init];
    self.orientationObserver = obs;

    __weak QFHUDController *weakSelf = self;
    @try {
        id<QFOrientationObserver> o2 = (id<QFOrientationObserver>)obs;
        [o2 setHandler:^(id orientationUpdate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                QFHUDController *s = weakSelf;
                if (!s) return;
                long long o = 0;
                @try {
                    o = [((id<QFOrientationUpdate>)orientationUpdate) orientation];
                } @catch (NSException *e) { }
                [s updateOrientation:(UIInterfaceOrientation)o];
            });
        }];
    } @catch (NSException *e) { }
}

- (void)updateOrientation:(UIInterfaceOrientation)o {
    if (o == _orientation) return;
    _orientation = o;
    if (o == UIInterfaceOrientationUnknown) return;

    CGRect b = [UIScreen mainScreen].bounds;
    CGFloat W = b.size.width;
    CGFloat H = b.size.height;
    if (UIInterfaceOrientationIsLandscape(o)) { CGFloat t = W; W = H; H = t; }

    UIWindow *win = self.view.window;
    if (win) {
        win.frame = CGRectMake(0, 0, W, H);
        [self reRegisterWindow:win];
    }
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self layoutRow];
}

- (void)reRegisterWindow:(UIWindow *)win {
    Class cls = objc_getClass("SBSAccessibilityWindowHostingController");
    if (!cls || !win) return;
    id controller = [[cls alloc] init];

    unsigned ctx = [win _contextId];
    double lvl = [win windowLevel];

    @try {
        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:controller];
        [inv setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
        [inv setArgument:&ctx atIndex:2];
        [inv setArgument:&lvl atIndex:3];
        [inv invoke];
    } @catch (NSException *e) { }
}

#pragma mark - QFRowViewDelegate

- (void)rowViewDidTapSettings:(QFRowView *)rowView {
    if (self.panelView) return;
    self.panelView = [[QFPanelView alloc] initWithFrame:self.view.bounds];
    self.panelView.delegate = self;
    [self.panelView presentInView:self.view animated:YES];
}

- (void)rowView:(QFRowView *)rowView didDragToCenter:(CGPoint)center {
    QFPrefs *p = [QFPrefs shared];
    CGFloat W = CGRectGetWidth(self.view.bounds);
    CGFloat H = CGRectGetHeight(self.view.bounds);
    if (W > 0 && H > 0) {
        p.posX = center.x / W;
        p.posY = center.y / H;
    }
}

- (void)rowViewDidEndDragging:(QFRowView *)rowView {
    [[QFPrefs shared] save];
}

#pragma mark - QFPanelViewDelegate

- (void)panelDidClose:(QFPanelView *)panel {
    [panel dismissAnimated:YES];
    self.panelView = nil;
}

- (void)panelPrefsChanged:(QFPanelView *)panel {
    // 重新读一遍偏好并重建外观
    [[QFPrefs shared] load];
    [self.rowView applyPrefs];
    [self layoutRow];
}

- (void)panelDidRequestExit:(QFPanelView *)panel {
    @try {
        [[UIApplication sharedApplication] terminateWithSuccess];
    } @catch (NSException *e) { }
    exit(0);
}

@end

#pragma mark - UIApplication 子类

@interface QFHUDApplication : UIApplication
@end

@implementation QFHUDApplication

- (instancetype)init {
    if (self = [super init]) {
        @try {
            UIEventDispatcher *dispatcher = (UIEventDispatcher *)[self valueForKey:@"eventDispatcher"];
            if (!dispatcher) {
                NSLog(@"[QFMonitor] failed to get _eventDispatcher");
            } else {
                if ([dispatcher respondsToSelector:@selector(_installEventRunLoopSources:)]) {
                    [dispatcher _installEventRunLoopSources:CFRunLoopGetMain()];
                }
                Class fetcherCls = objc_getClass("UIEventFetcher");
                if (fetcherCls) {
                    UIEventFetcher *fetcher = [[fetcherCls alloc] init];
                    if ([fetcher respondsToSelector:@selector(setEventFetcherSink:)]) {
                        [fetcher setEventFetcherSink:dispatcher];
                    } else {
                        [fetcher setValue:dispatcher forKey:@"eventFetcherSink"];
                    }
                    // 上游 TrollSpeed 设置两处: dispatcher.eventFetcher 和 application.eventFetcher
                    // 少了前者会导致 HID 事件没有消费者
                    @try {
                        [dispatcher setValue:fetcher forKey:@"eventFetcher"];
                    } @catch (NSException *e) {
                        QFLog(@"dispatcher.eventFetcher failed: %@", e.reason);
                    }
                    [self setValue:fetcher forKey:@"eventFetcher"];
                }
            }
        } @catch (NSException *e) {
            NSLog(@"[QFMonitor] event dispatcher setup failed: %@", e.reason);
        }
    }
    return self;
}

@end

#pragma mark - Delegate

@interface QFHUDApplicationDelegate : NSObject <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation QFHUDApplicationDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    QFLog(@"didFinishLaunchingWithOptions ENTER");

    QFHUDController *vc = [[QFHUDController alloc] init];
    QFLog(@"controller = %@", vc);

    QFLog(@"screen bounds = %@", NSStringFromCGRect([UIScreen mainScreen].bounds));
    QFHUDWindow *win = [[QFHUDWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    QFLog(@"window allocated = %@ frame=%@", win, NSStringFromCGRect(win.frame));
    win.rootViewController = vc;
    win.windowLevel = 10000010.0;
    win.backgroundColor = [UIColor clearColor];
    win.hidden = NO;
    [win makeKeyAndVisible];
    self.window = win;
    QFLog(@"window visible=%d hidden=%d level=%.0f contextId=%u windows=%lu",
          win.isKeyWindow, win.hidden, win.windowLevel, [win _contextId],
          (unsigned long)[[UIApplication sharedApplication].windows.count]);

    [self registerWindow:win];
    QFLog(@"didFinishLaunchingWithOptions DONE");
    return YES;
}

- (void)registerWindow:(UIWindow *)win {
    Class cls = objc_getClass("SBSAccessibilityWindowHostingController");
    QFLog(@"registerWindow: SBS class = %@", cls);
    if (!cls) {
        QFLog(@"[QFMonitor] SBSAccessibilityWindowHostingController not found");
        return;
    }
    id controller = [[cls alloc] init];
    QFLog(@"SBS controller = %@", controller);

    unsigned ctx = [win _contextId];
    double lvl = [win windowLevel];
    QFLog(@"registerWindowWithContextID ctx=%u level=%.0f", ctx, lvl);

    @try {
        NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"v@:Id"];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
        [inv setTarget:controller];
        [inv setSelector:NSSelectorFromString(@"registerWindowWithContextID:atLevel:")];
        [inv setArgument:&ctx atIndex:2];
        [inv setArgument:&lvl atIndex:3];
        [inv invoke];
        QFLog(@"registerWindow invoked OK");
    } @catch (NSException *e) {
        QFLog(@"[QFMonitor] registerWindow failed: %@", e.reason);
    }
}

@end

#pragma mark - 进程级接口

int QFRunHUDProcess(void) {
    @autoreleasepool {
        QFLogReset();
        QFLog(@"HUD process start (uid=%d euid=%d)", getuid(), geteuid());

        NSString *pidStr = [NSString stringWithFormat:@"%d", getpid()];
        BOOL wrote = [pidStr writeToFile:QF_PID_PATH
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:nil];
        QFLog(@"pid file write %@ -> %@", wrote ? @"OK" : @"FAIL", QF_PID_PATH);

        [UIScreen initialize];
        CFRunLoopGetCurrent();
        QFLog(@"screen init OK, bounds=%@", NSStringFromCGRect([UIScreen mainScreen].bounds));

        GSInitialize();
        QFLog(@"GSInitialize done");
        BKSDisplayServicesStart();
        QFLog(@"BKSDisplayServicesStart done");
        UIApplicationInitialize();
        QFLog(@"UIApplicationInitialize done");

        Class appCls = objc_getClass("QFHUDApplication");
        QFLog(@"QFHUDApplication class = %@", appCls);
        UIApplicationInstantiateSingleton(appCls);
        QFLog(@"UIApplicationInstantiateSingleton done, shared=%@", UIApplication.sharedApplication);

        static id<UIApplicationDelegate> sAppDelegate = nil;
        sAppDelegate = [[objc_getClass("QFHUDApplicationDelegate") alloc] init];
        QFLog(@"delegate = %@", sAppDelegate);
        [UIApplication.sharedApplication setDelegate:sAppDelegate];
        [UIApplication.sharedApplication _accessibilityInit];
        QFLog(@"_accessibilityInit done");

        if (@available(iOS 15.0, *)) {
            GSEventInitialize(0);
            GSEventPushRunLoopMode(kCFRunLoopDefaultMode);
            QFLog(@"GSEventInitialize done");
        }

        QFLog(@"calling __completeAndRunAsPlugin ...");
        [UIApplication.sharedApplication __completeAndRunAsPlugin];
        QFLog(@"__completeAndRunAsPlugin returned; windows=%lu",
              (unsigned long)[[UIApplication.sharedApplication windows] count]);

        [QFTouchBridge install];
        QFLog(@"touch bridge installed");

        QFLog(@"entering CFRunLoopRun");
        CFRunLoopRun();
        QFLog(@"CFRunLoopRun returned (unexpected)");
    }
    return EXIT_SUCCESS;
}

#pragma mark - 启动 / 停止

static char *QFCopyExecutablePath(void) {
    uint32_t size = 0;
    _NSGetExecutablePath(NULL, &size);
    if (!size) return NULL;
    char *p = (char *)calloc(1, size);
    _NSGetExecutablePath(p, &size);
    return p;
}

static int QFRunHelper(const char *arg) {
    char *exe = QFCopyExecutablePath();
    if (!exe) return -1;

    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    const char *args[] = { exe, arg, NULL };
    pid_t child = -1;
    int rc = posix_spawn(&child, exe, NULL, &attr, (char **)args, environ);
    posix_spawnattr_destroy(&attr);

    if (rc != 0) {
        free(exe);
        return -1;              // spawn 失败
    }
    int status = 0;
    waitpid(child, &status, 0);
    free(exe);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 0;
}

void QFStartHUD(void) {
    char *exe = QFCopyExecutablePath();
    if (!exe) return;

    const char *args[] = { exe, "-hud", NULL };
    pid_t child = -1;
    int rc = -1;

    // 优先用 platform persona + uid 0 启动(HUD 需要 root 才能全局显示)
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    int p1 = posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    int p2 = posix_spawnattr_set_persona_uid_np(&attr, 0);
    int p3 = posix_spawnattr_set_persona_gid_np(&attr, 0);
    QFLog(@"persona calls: set=%d uid=%d gid=%d", p1, p2, p3);
    rc = posix_spawn(&child, exe, NULL, &attr, (char **)args, environ);
    QFLog(@"posix_spawn(persona) rc=%d child=%d", rc, child);
    posix_spawnattr_destroy(&attr);

    // 退路: 不带 persona 直接启动
    if (rc != 0) {
        QFLog(@"persona spawn failed rc=%d, falling back to plain spawn", rc);
        posix_spawnattr_t attr2;
        posix_spawnattr_init(&attr2);
        posix_spawnattr_setpgroup(&attr2, 0);
        posix_spawnattr_setflags(&attr2, POSIX_SPAWN_SETPGROUP);
        rc = posix_spawn(&child, exe, NULL, &attr2, (char **)args, environ);
        QFLog(@"posix_spawn(plain) rc=%d child=%d", rc, child);
        posix_spawnattr_destroy(&attr2);
    }

    if (rc == 0) {
        int st = 0;
        waitpid(child, &st, WNOHANG);   // 不等待, 让它独立跑
        QFLog(@"HUD spawned pid=%d", child);
    } else {
        QFLog(@"HUD spawn FAILED rc=%d (%s)", rc, strerror(rc));
    }
    free(exe);
}

void QFStopHUD(void) {
    if (QFRunHelper("-exit") == 0) return;
    // 退路: 直接按 pid 文件结束(本进程本身有权限时可用)
    NSString *pidStr = [NSString stringWithContentsOfFile:QF_PID_PATH
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    if (pidStr.length) {
        pid_t pid = (pid_t)[pidStr intValue];
        if (pid > 0) kill(pid, SIGKILL);
        unlink(QF_PID_PATH_C);
    }
}

BOOL QFIsHUDRunning(void) {
    NSString *pidStr = [NSString stringWithContentsOfFile:QF_PID_PATH
                                                 encoding:NSUTF8StringEncoding
                                                    error:nil];
    if (pidStr.length) {
        pid_t pid = (pid_t)[pidStr intValue];
        if (pid > 0 && kill(pid, 0) == 0) return YES;
    }
    // 直接查不到(可能因为 HUD 是 root 进程)时, 用 root helper 再确认一次
    int rc = QFRunHelper("-check");
    if (rc < 0) return NO;
    return (rc != 0);
}
