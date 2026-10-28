//
//  QFMonitorController.h
//  主控制器：管理悬浮监控窗 + 设置抽屉。
//

#import <UIKit/UIKit.h>

@interface QFMonitorController : UIViewController

+ (instancetype)shared;

// 悬浮窗的 window（悬浮条所在，级别最高）
@property (nonatomic, strong, readonly) UIWindow *floatWindow;

@end