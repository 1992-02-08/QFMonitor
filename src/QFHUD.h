//
//  QFHUD.h — HUD 插件进程
//
//  TrollSpeed 的全局悬浮原理(MIT 上游):
//    main() 无参数 -> 启动器 UI
//    main() 带 -hud -> HUD 插件进程
//  HUD 进程用 SBSAccessibilityWindowHostingController 把窗口注册给 SpringBoard,
//  从而可以显示在所有 App 之上。
//
#ifndef QFHUD_H
#define QFHUD_H

#import <UIKit/UIKit.h>

int  QFRunHUDProcess(void);      // 在当前进程里跑 HUD 插件
BOOL QFIsHUDRunning(void);       // 悬浮窗是否已在运行
void QFStartHUD(void);           // 以 root 权限 spawn HUD 进程
void QFStopHUD(void);            // 结束 HUD 进程

@interface QFHUDController : UIViewController
@end

#endif /* QFHUD_H */
