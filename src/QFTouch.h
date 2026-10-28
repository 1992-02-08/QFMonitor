//
//  QFTouch.h — 把 HID 触摸事件合成为 UITouch 并投递给 UIKit
//
//  全局悬浮窗口不属于任何前台 App, 系统不会给它发触摸。
//  TrollSpeed 的做法是: BackBoardServices 注册 HID 回调, 用
//  AccessibilityUtilities 的 AXEventRepresentation 解出坐标与阶段,
//  再手工造 UITouch 交给 UIApplication sendEvent:。
//  下面按同一思路实现(上游 MIT 协议)。
//
#ifndef QFTOUCH_H
#define QFTOUCH_H

#import <UIKit/UIKit.h>
#import "QFPrivate.h"

@interface QFTouchBridge : NSObject

+ (void)install;                                              // 注册 HID 回调
+ (void)feedAtPoint:(CGPoint)point
               phase:(UITouchPhase)phase
           pointerId:(NSInteger)pointerId;

@end

#endif /* QFTOUCH_H */
