//
//  QFRowView.h
//  单条全透明悬浮监控条。文字尺寸紧贴内容、无背景、带紧贴阴影。
//  整条可拖拽；双击或点齿轮打开设置面板。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^QFRowViewAction)(void);

@interface QFRowView : UIView

// 打开设置的回调（齿轮 / 双击）
@property (nonatomic, copy) QFRowViewAction onOpenSettings;

// 依据当前配置刷新显示
- (void)refreshDisplay;

// 从(归一化)位置同步到屏幕上的 frame
- (void)syncFromNormalizedPosition;

@end

NS_ASSUME_NONNULL_END