//
//  QFPanelView.h
//  底部抽屉设置面板：仅顶部两角圆角，高为屏高 76%。
//  包含：实时预览 / 字号滑杆+4档预设 / 整体缩放 / 显示开关 / 位置重置 / 触摸穿透 / 结束悬浮窗 / 退出App。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QFPanelView : UIView

// 回调
@property (nonatomic, copy, nullable) void(^onResetPosition)(void);
@property (nonatomic, copy, nullable) void(^onEndFloat)(void);
@property (nonatomic, copy, nullable) void(^onExitApp)(void);

// 显示面板（从底部滑入）
- (void)present;
// 收起面板
- (void)dismiss;
// 设置变更后刷新预览等
- (void)refresh;

// 内部：触摸穿透按钮（外观同步用）
@property (nonatomic, strong, nullable) UIButton *passthroughButton;

@end

NS_ASSUME_NONNULL_END