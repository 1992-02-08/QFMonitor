//
//  QFPanelView.h — 自写底部抽屉设置面板
//
//  完全独立于 TrollSpeed 原生面板, 自己设计:
//    深色磨砂卡片 + 顶部抓手 + 标题 + 滚动内容区
//    分组: 实时预览 / 字号(滑杆+四档预设) / 整体缩放 / 显示项目(7 个开关)
//          / 配色 / 位置 / 操作
//
#ifndef QFPANELVIEW_H
#define QFPANELVIEW_H

#import <UIKit/UIKit.h>

@class QFPanelView;

@protocol QFPanelViewDelegate <NSObject>
- (void)panelDidClose:(QFPanelView *)panel;
- (void)panelPrefsChanged:(QFPanelView *)panel;
- (void)panelDidRequestExit:(QFPanelView *)panel;
@end

@interface QFPanelView : UIView

@property (nonatomic, weak) id<QFPanelViewDelegate> delegate;

- (void)presentInView:(UIView *)host animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated;
- (void)refreshPreview;

@end

#endif /* QFPANELVIEW_H */
