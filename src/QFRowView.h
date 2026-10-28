//
//  QFRowView.h — 悬浮条本体
//
//  设计要点(按用户要求):
//    * 只有一行文字, 横排:  ↓ 12M  ↑ 340K  ⚡92%  34°  -1.28W  CPU 18%  FPS 60
//    * 完全无背景: 没有底卡 / 没有描边 / 没有圆角 / 没有投影;
//      视图自身 backgroundColor = clear, layer 无 border 无 shadow。
//    * 尺寸完全由文字决定, 高度贴合文字。
//    * 末尾一个齿轮图标作为"设置"按钮(同样是纯图形, 无底色)。
//    * 整条可拖动, 横竖屏都支持。
//
#ifndef QFROWVIEW_H
#define QFROWVIEW_H

#import <UIKit/UIKit.h>

@class QFRowView;

@protocol QFRowViewDelegate <NSObject>
- (void)rowViewDidTapSettings:(QFRowView *)rowView;
- (void)rowView:(QFRowView *)rowView didDragToCenter:(CGPoint)center;
- (void)rowViewDidEndDragging:(QFRowView *)rowView;
@end

@interface QFRowView : UIView

@property (nonatomic, weak) id<QFRowViewDelegate> delegate;

// 依据当前指标 + 偏好刷新文字与尺寸
- (void)refreshText;

// 依据当前指标刷新, 并限制悬浮条总宽不超过 maxWidth(超出则自动缩字号)
- (void)refreshTextConstrainedToWidth:(CGFloat)maxWidth;

// 依据偏好(字号 / 缩放 / 配色 / 显示开关)重建外观
- (void)applyPrefs;

@end

#endif /* QFROWVIEW_H */
