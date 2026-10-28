//
//  QFTouchBridge.m
//
//  HID 事件 -> AXEventRepresentation -> 合成 UITouch -> UIApplication sendEvent:
//

#import "QFTouch.h"
#import "AXEventRepresentation.h"
#import "UITouch-KIFAdditions.h"
#import "UIApplication+Private.h"
#import "UIEvent+Private.h"
#import "UIWindow+Private.h"

#import <string.h>

static void QFHIDEventCallback(void *target, void *refcon,
                               IOHIDServiceRef service, IOHIDEventRef event);

#pragma mark - 触点条目

@interface QFTouchEntry : NSObject
@property (nonatomic, assign) NSInteger pointerId;
@property (nonatomic, strong) UITouch    *touch;
@property (nonatomic, assign) BOOL       dead;
@end

@implementation QFTouchEntry
@end

#pragma mark - 全局状态

static NSMutableArray     *gEntries = nil;   // QFTouchEntry
static CFRunLoopSourceRef  gSource  = NULL;
static UIWindow            *gKeyWindow = nil;

static void QFFlushEvent(void *info) {
    UIApplication *app = [UIApplication sharedApplication];
    if (!app) return;

    UIEvent *event = [app _touchesEvent];
    if (!event) return;

    [event _clearTouches];
    for (QFTouchEntry *e in gEntries) {
        if (e.touch) [event _addTouch:e.touch forDelayedDelivery:NO];
    }
    [app sendEvent:event];

    // 投递完再移除已结束的触点
    NSMutableArray *dead = [NSMutableArray array];
    for (QFTouchEntry *e in gEntries) {
        if (e.dead) [dead addObject:e];
    }
    [gEntries removeObjectsInArray:dead];
}

@implementation QFTouchBridge

+ (void)install {
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        gEntries = [NSMutableArray array];

        CFRunLoopSourceContext ctx;
        memset(&ctx, 0, sizeof(CFRunLoopSourceContext));
        ctx.perform = QFFlushEvent;
        gSource = CFRunLoopSourceCreate(kCFAllocatorDefault, -2, &ctx);
        CFRunLoopRef loop = CFRunLoopGetMain();
        if (gSource && loop) {
            CFRunLoopAddSource(loop, gSource, kCFRunLoopCommonModes);
        }

        BKSHIDEventRegisterEventCallback(QFHIDEventCallback);
    });
}

+ (void)feedAtPoint:(CGPoint)point
               phase:(UITouchPhase)phase
           pointerId:(NSInteger)pointerId {
    if (!gEntries) return;

    // 取当前 key window(HUD 窗口)
    if (!gKeyWindow) {
        UIApplication *app = [UIApplication sharedApplication];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        gKeyWindow = [[app windows] firstObject];
#pragma clang diagnostic pop
    }
    UIWindow *window = gKeyWindow;
    if (!window) return;

    NSInteger pid = pointerId;
    if (pid < 0) pid = 0;

    QFTouchEntry *entry = nil;
    for (QFTouchEntry *e in gEntries) {
        if (e.pointerId == pid) { entry = e; break; }
    }

    if (phase == UITouchPhaseBegan && !entry) {
        UIView *view = [window hitTest:point withEvent:nil];
        UITouch *t = [[UITouch alloc] initAtPoint:point inWindow:window onView:view];
        if (!t) return;

        // 新触点落下时, 其它触点转为 Stationary(与系统行为一致)
        for (QFTouchEntry *o in gEntries) {
            if (o.touch.phase == UITouchPhaseBegan) {
                [o.touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
            }
        }

        entry = [[QFTouchEntry alloc] init];
        entry.pointerId = pid;
        entry.touch = t;
        [gEntries addObject:entry];
    }

    if (!entry) {
        // 宽容处理: 没收到 Began 也照样建一个
        UIView *view = [window hitTest:point withEvent:nil];
        UITouch *t = [[UITouch alloc] initAtPoint:point inWindow:window onView:view];
        if (!t) return;
        entry = [[QFTouchEntry alloc] init];
        entry.pointerId = pid;
        entry.touch = t;
        [gEntries addObject:entry];
    }

    UITouch *t = entry.touch;
    if (phase != UITouchPhaseBegan) {
        [t setLocationInWindow:point];
    }
    [t setPhaseAndUpdateTimestamp:phase];
    entry.dead = (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled);

    if (gSource) CFRunLoopSourceSignal(gSource);
}

@end

#pragma mark - HID 回调

static void QFHIDEventCallback(void *target, void *refcon,
                               IOHIDServiceRef service, IOHIDEventRef event) {
    static Class AXRepCls = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AccessibilityUtilities.framework"] load];
        AXRepCls = objc_getClass("AXEventRepresentation");
    });
    if (!AXRepCls) return;

    // iOS 15.1 以下没有 AX 这条路, 直接把 HID 事件塞进 UIApplication 的队列
    if (@available(iOS 15.1, *)) {
        // 走 AX
    } else {
        @try {
            UIApplication *app = [UIApplication sharedApplication];
            [app _enqueueHIDEvent:event];
        } @catch (NSException *e) { }
        return;
    }

    @try {
        AXEventRepresentation *rep = [AXRepCls representationWithHIDEvent:event
                                                    hidStreamIdentifier:@"UIApplicationEvents"];
        if (!rep) return;

        UITouchPhase phase = UITouchPhaseEnded;
        if ([rep isTouchDown])                      phase = UITouchPhaseBegan;
        else if ([rep isMove])                      phase = UITouchPhaseMoved;
        else if ([rep isCancel])                    phase = UITouchPhaseCancelled;
        else if ([rep isLift] || [rep isInRange] || [rep isInRangeLift])
                                                   phase = UITouchPhaseEnded;

        CGPoint loc = [rep location];
        NSInteger pid = (NSInteger)[[[[rep handInfo] paths] firstObject] pathIdentity];

        dispatch_async(dispatch_get_main_queue(), ^{
            [QFTouchBridge feedAtPoint:loc phase:phase pointerId:pid];
        });
    } @catch (NSException *e) { }
}
