//
//  QFPrivate.h — 私有符号声明
//
//  全局悬浮原理(与 TrollSpeed 上游一致, MIT 协议):
//    1. App 带 platform-application / springboard.accessibility-window-hosting /
//       QuartzCore.displayable-context 三个 entitlement;
//    2. 创建 UIWindow, 覆写 _isSystemWindow 等私有方法;
//    3. 用 SBSAccessibilityWindowHostingController 的
//       registerWindowWithContextID:atLevel: 把窗口注册给 SpringBoard,
//       于是窗口可以显示在所有 App 之上;
//    4. 触摸通过 BackBoardServices 的 HID 回调 -> AccessibilityUtilities 的
//       AXEventRepresentation -> 合成 UITouch -> sendEvent:。
//
//  本文件只放 C 函数与 C 类型别名; ObjC 侧的私有声明分散在
//  UIWindow+Private.h / UIApplication+Private.h / UIEvent+Private.h /
//  UITouch+Private.h / UIEventDispatcher.h / UIEventFetcher.h /
//  SBSAccessibilityWindowHostingController.h / AXEventRepresentation.h
//
#ifndef QFPRIVATE_H
#define QFPRIVATE_H

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef struct __IOHIDEvent    *IOHIDEventRef;
typedef struct __IOHIDService  *IOHIDServiceRef;
typedef struct __IOHIDNotification *IOHIDNotificationRef;
typedef struct __GSEvent       *GSEventRef;

// ------------------------------------------------------------ 私有框架 C 函数
#ifdef __cplusplus
extern "C" {
#endif
void *BKSHIDEventRegisterEventCallback(void (*)(void *, void *, IOHIDServiceRef, IOHIDEventRef));
void BKSDisplayServicesStart(void);
void GSInitialize(void);
void GSEventInitialize(Boolean registerPurple);
void GSEventPushRunLoopMode(CFStringRef mode);
void GSEventPopRunLoopMode(CFStringRef mode);
void UIApplicationInitialize(void);
void UIApplicationInstantiateSingleton(id aclass);
#ifdef __cplusplus
}
#endif

#endif /* QFPRIVATE_H */
