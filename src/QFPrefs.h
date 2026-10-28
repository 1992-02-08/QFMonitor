//
//  QFPrefs.h — 设置项与持久化
//
//  存储位置沿用 TrollSpeed 的做法: 直接写一个 plist 文件到
//  /var/mobile/Library/Preferences/com.qfmonitor.hud.plist
//  启动器进程(mobile 用户)与 HUD 进程(root persona)都能读写同一份数据。
//
#ifndef QFPREFS_H
#define QFPREFS_H

#import <Foundation/Foundation.h>

extern NSString *const QFPrefsPath;

@interface QFPrefs : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) double   fontSize;   // 8 ~ 24 pt
@property (nonatomic, assign) double   scale;      // 0.6 ~ 2.0 整体缩放
@property (nonatomic, assign) BOOL     showDown;
@property (nonatomic, assign) BOOL     showUp;
@property (nonatomic, assign) BOOL     showBattery;
@property (nonatomic, assign) BOOL     showTemp;
@property (nonatomic, assign) BOOL     showPower;
@property (nonatomic, assign) BOOL     showCurrent;
@property (nonatomic, assign) BOOL     showCPU;
@property (nonatomic, assign) BOOL     showFPS;
@property (nonatomic, assign) double   posX;       // 归一化中心位置 0~1
@property (nonatomic, assign) double   posY;
@property (nonatomic, assign) NSInteger accent;     // 配色序号
@property (nonatomic, assign) BOOL     passthrough; // 触摸穿透(悬浮条不挡住下面的 App)
@property (nonatomic, assign) BOOL     locked;      // 锁定位置(拖动无效, 只能按钮/微调移动)
@property (nonatomic, assign) BOOL     freeDrag;    // 自由移动(拖动开关)

- (void)load;
- (void)save;
- (void)resetPosition;
// 若文件被别的进程改过则重新载入, 返回 YES 表示有变化
- (BOOL)reloadIfChanged;

@end

#endif /* QFPREFS_H */
