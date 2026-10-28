//
//  QFMonitorController.m
//  主控制器：把悬浮条挂到主窗口顶层，负责设置抽屉的展示与生命周期。
//

#import "QFMonitorController.h"
#import "QFRowView.h"
#import "QFPanelView.h"
#import "QFPrefs.h"
#import "QFMetrics.h"

@interface QFMonitorController ()
@property (nonatomic, strong, readwrite) UIWindow *floatWindow;
@property (nonatomic, strong) QFRowView *rowView;
@property (nonatomic, strong) QFPanelView *panel;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, assign) BOOL panelPresented;
@end

@implementation QFMonitorController

+ (instancetype)shared {
    static QFMonitorController *c;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ c = [[QFMonitorController alloc] init]; });
    return c;
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1.0];
    // 说明页：告诉用户悬浮条已在顶部
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, self.view.bounds.size.width - 40, 60)];
    info.text = @"悬浮监控条正在运行\n拖拽移动 · 双击或齿轮打开设置";
    info.numberOfLines = 2;
    info.textAlignment = NSTextAlignmentCenter;
    info.textColor = [UIColor whiteColor];
    info.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.view addSubview:info];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startFloatingIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.rowView) {
        [self.rowView syncFromNormalizedPosition];
    }
}

#pragma mark - 悬浮条

- (void)startFloatingIfNeeded {
    if (self.rowView) return;

    // 用主窗口的根视图承载（方案A内，悬浮条在 App 内最顶层）
    UIView *host = self.view.window ?: self.view;
    self.floatWindow = self.view.window;

    _rowView = [[QFRowView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)];
    __weak typeof(self) wself = self;
    _rowView.onOpenSettings = ^{ [wself openPanel]; };
    [host addSubview:_rowView];
    [_rowView syncFromNormalizedPosition];

    // 启动采集 + 刷新
    [[QFMetrics shared] startSampling];
    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self
                                                   selector:@selector(_tick) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_refreshTimer forMode:NSRunLoopCommonModes];
    [self _tick];
}

- (void)_tick {
    [_rowView refreshDisplay];
    if (_panelPresented) [_panel refresh];
}

#pragma mark - 设置抽屉

- (void)openPanel {
    if (_panelPresented) return;
    _panelPresented = YES;

    UIView *host = self.view.window ?: self.view;
    CGRect b = host.bounds;
    _panel = [[QFPanelView alloc] initWithFrame:b];
    __weak typeof(self) wself = self;
    _panel.onResetPosition = ^{ [wself _resetPos]; };
    _panel.onEndFloat = ^{ [wself _endFloat]; };
    _panel.onExitApp = ^{ [wself _exitApp]; };
    [host addSubview:_panel];

    // 面板盖在悬浮条之上
    [host bringSubviewToFront:_panel];
    [_panel present];
}

- (void)closePanel {
    if (!_panelPresented) return;
    _panelPresented = NO;
    [_panel dismiss];
    _panel = nil;
}

- (void)_resetPos {
    // 已由 panel 保存归一化坐标，这里同步悬浮条
    [_rowView syncFromNormalizedPosition];
}

- (void)_endFloat {
    [self closePanel];
    [[QFMetrics shared] stopSampling];
    [_refreshTimer invalidate]; _refreshTimer = nil;
    [_rowView removeFromSuperview]; _rowView = nil;
    self.floatWindow = nil;
}

- (void)_exitApp {
    [self _endFloat];
    exit(0);
}

#pragma mark - 旋转（保持归一化位置）

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self->_panelPresented) {
            self->_panel.frame = CGRectMake(0, 0, size.width, size.height);
        }
        [self.rowView syncFromNormalizedPosition];
    } completion:nil];
}

@end