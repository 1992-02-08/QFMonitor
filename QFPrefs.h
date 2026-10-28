//
//  QFPrefs.h
//  用户配置：字号 / 缩放 / 显示开关 / 位置 / 触摸穿透。
//  全部即时生效并持久化到 NSUserDefaults。
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QFPrefs : NSObject

+ (instancetype)shared;

// 字号（8–24，默认 11）与预设
@property (nonatomic, assign) CGFloat fontSize;
// 整体缩放（0.6–2.0，默认 1.0）
@property (nonatomic, assign) CGFloat scaleFactor;

// 显示开关（全部默认开）
@property (nonatomic, assign) BOOL showCPU;
@property (nonatomic, assign) BOOL showFPS;
@property (nonatomic, assign) BOOL showDown;
@property (nonatomic, assign) BOOL showUp;
@property (nonatomic, assign) BOOL showBattery;
@property (nonatomic, assign) BOOL showTemp;
@property (nonatomic, assign) BOOL showPower;

// 归一化位置（0–1，相对屏幕宽高）；默认顶中
@property (nonatomic, assign) CGPoint normalizedPosition;

// 触摸穿透（不拦截悬浮条触摸）
@property (nonatomic, assign) BOOL passthrough;

// 读取 / 保存
- (void)load;
- (void)save;

// 字号预设（pt）
+ (CGFloat)presetSize:(NSInteger)idx; // 0小9 1标准11 2大14 3特大18

@end