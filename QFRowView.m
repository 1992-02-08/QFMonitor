//
//  QFRowView.m
//  全透明可拖拽悬浮监控条。
//

#import "QFRowView.h"
#import "QFMetrics.h"
#import "QFPrefs.h"
#import <QuartzCore/QuartzCore.h>

@interface QFRowView ()
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIButton *gearButton;
@property (nonatomic, strong) QFMetrics *metrics;

// 拖拽
@property (nonatomic, assign) CGPoint dragStartCenter;
@property (nonatomic, assign) CGPoint dragStartPoint;
@property (nonatomic, assign) BOOL dragging;
@end

@implementation QFRowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self _build];
    return self;
}

- (void)_build {
    _metrics = [QFMetrics shared];

    // 背景 / 视图全部清空：无卡片、无线、无圆角、无阴影；仅文字带紧贴阴影
    self.backgroundColor = [UIColor clearColor];
    self.layer.backgroundColor = [UIColor clearColor].CGColor;
    self.layer.borderWidth = 0;
    self.layer.cornerRadius = 0;
    self.layer.shadowOpacity = 0;
    self.userInteractionEnabled = YES;
    self.clipsToBounds = NO;

    _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _textLabel.backgroundColor = [UIColor clearColor];
    _textLabel.textColor = [UIColor whiteColor];
    _textLabel.userInteractionEnabled = NO;
    [self addSubview:_textLabel];

    _gearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _gearButton.tintColor = [UIColor whiteColor];
    [_gearButton setTitle:@"⚙︎" forState:UIControlStateNormal]; // 齿轮字符
    _gearButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    [_gearButton addTarget:self action:@selector(_gearTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_gearButton];

    // 双击打开设置
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_openSettings)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];

    // 拖拽 pan
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_pan:)];
    [self addGestureRecognizer:pan];

    [self refreshDisplay];
}

#pragma mark - 显示刷新

- (void)refreshDisplay {
    QFPrefs *p = [QFPrefs shared];
    CGFloat unit = p.fontSize * p.scaleFactor;   // 基础字号 × 缩放

    // 逐个拼装文本（保持顺序：CPU/FPS/下行/上行/电量/温度/功率）
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] init];

    if (p.showCPU)   [as appendAttributedString:[self _text:[NSString stringWithFormat:@"CPU %.0f%%", _metrics.cpuPercent] size:unit hot:NO]];
    if (p.showFPS)   [as appendAttributedString:[self _text:[NSString stringWithFormat:@"%@%ld", as.length?@" ":@"", (long)_metrics.fps] size:unit hot:NO]];

    if (p.showDown)  [as appendAttributedString:[self _text:[NSString stringWithFormat:@"%@↓%@", as.length?@" ":@"", [self _netText:_metrics.downBps]] size:unit hot:NO]];
    if (p.showUp)    [as appendAttributedString:[self _text:[NSString stringWithFormat:@"%@↑%@", as.length?@" ":@"", [self _netText:_metrics.upBps]] size:unit hot:NO]];

    if (p.showBattery)[as appendAttributedString:[self _text:[NSString stringWithFormat:@"%@%ld%%%@", as.length?@" ":@"", (long)_metrics.batteryLevel, _metrics.charging?@"⚡":@""] size:unit hot:(_metrics.batteryLevel>=0 && _metrics.batteryLevel<20)]];

    if (p.showTemp) {
        NSString *t = _metrics.temperature <= -1000 ? @"--°" : [NSString stringWithFormat:@"%ld°", (long)_metrics.temperature];
        [as appendAttributedString:[self _text:[NSString stringWithFormat:@"%@%@", as.length?@" ":@"", t] size:unit hot:NO]];
    }

    if (p.showPower) {
        NSString *w = _metrics.wattValid ? [NSString stringWithFormat:@"%+.1fW", _metrics.watt] : @"--W";
        [as appendAttributedString:[self _text:[NSString stringWithFormat:@"%@%@", as.length?@" ":@"", w] size:unit hot:NO]];
    }

    _textLabel.attributedText = as;
    [_textLabel sizeToFit];
    [self _layout];
}

// 网络数值文本：<1024 显示 B，<1024K 显示 K(0小数)，<1024M 显示 M(1小数)
- (NSString *)_netText:(double)b {
    if (b < 1024.0) return [NSString stringWithFormat:@"%.0fB", b];
    double k = b / 1024.0;
    if (k < 1024.0) return [NSString stringWithFormat:@"%.0fK", k];
    double m = k / 1024.0;
    return [NSString stringWithFormat:@"%.1fM", m];
}

- (NSAttributedString *)_text:(NSString *)str size:(CGFloat)size hot:(BOOL)hot {
    NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
    para.maximumLineHeight = ceil(size * 1.1);
    para.minimumLineHeight = ceil(size * 1.1);

    UIColor *color = hot ? [UIColor redColor] : [UIColor whiteColor];
    // 紧贴文字阴影：blur=1.2，零偏移
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowBlurRadius = 1.2;
    shadow.shadowOffset = CGSizeZero;

    NSDictionary *attr = @{
        NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:size] ?: [UIFont systemFontOfSize:size weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: color,
        NSShadowAttributeName: shadow,
        NSParagraphStyleAttributeName: para,
    };
    return [[NSAttributedString alloc] initWithString:str attributes:attr];
}

- (void)_layout {
    // 高度完全包裹文字；紧贴
    CGSize t = _textLabel.bounds.size;
    CGFloat fontH = t.height;
    // 齿轮放在右侧，与文字同高
    CGFloat gearW = ceil(fontH * 1.0);   // 齿轮宽约一行高
    _gearButton.frame = CGRectMake(t.width + 3, 0, gearW, fontH);

    CGFloat totalW = t.width + ( _gearButton.hidden ? 0 : gearW + 3 );
    CGRect f = self.frame;
    f.size = CGSizeMake(MAX(totalW, 1), MAX(fontH, 1));
    f.origin = [self _clampOrigin:f.origin size:f.size];
    self.frame = f;

    _textLabel.frame = CGRectMake(0, 0, t.width, fontH);
}

// 拖拽 / 旋转时把原点限制在屏幕内
- (CGPoint)_clampOrigin:(CGPoint)o size:(CGSize)s {
    CGRect sb = [UIScreen mainScreen].bounds;
    CGFloat x = MIN(MAX(o.x, 0), MAX(0, sb.size.width - s.width));
    CGFloat y = MIN(MAX(o.y, 0), MAX(0, sb.size.height - s.height));
    return CGPointMake(x, y);
}

#pragma mark - 拖拽

- (void)_pan:(UIPanGestureRecognizer *)pan {
    UIView *sv = self.superview;
    if (pan.state == UIGestureRecognizerStateBegan) {
        _dragging = YES;
        _dragStartCenter = self.center;
        _dragStartPoint  = [pan locationInView:sv];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint p = [pan locationInView:sv];
        CGPoint c = _dragStartCenter;
        c.x += p.x - _dragStartPoint.x;
        c.y += p.y - _dragStartPoint.y;
        self.center = c;
        // 防止越界
        CGRect frame = self.frame;
        frame.origin = [self _clampOrigin:frame.origin
                                     size:[self bounds].size];
        // 用 center 限制
        CGRect sb = sv ? sv.bounds : [UIScreen mainScreen].bounds;
        CGFloat cx = MIN(MAX(self.center.x, self.bounds.size.width/2), MAX(self.bounds.size.width/2, sb.size.width - self.bounds.size.width/2));
        CGFloat cy = MIN(MAX(self.center.y, self.bounds.size.height/2), MAX(self.bounds.size.height/2, sb.size.height - self.bounds.size.height/2));
        self.center = CGPointMake(cx, cy);
    } else if (pan.state == UIGestureRecognizerStateEnded ||
               pan.state == UIGestureRecognizerStateCancelled) {
        _dragging = NO;
        [self _persistNormalized];
    }
}

// 拖拽结束时把中心写回归一化坐标
- (void)_persistNormalized {
    UIView *sv = self.superview;
    CGRect sb = sv ? sv.bounds : [UIScreen mainScreen].bounds;
    if (sb.size.width <= 0 || sb.size.height <= 0) return;
    CGFloat nx = self.center.x / sb.size.width;
    CGFloat ny = self.center.y / sb.size.height;
    [QFPrefs shared].normalizedPosition = CGPointMake(nx, ny);
    [[QFPrefs shared] save];
}

- (void)syncFromNormalizedPosition {
    UIView *sv = self.superview;
    CGRect sb = sv ? sv.bounds : [UIScreen mainScreen].bounds;
    QFPrefs *p = [QFPrefs shared];
    CGPoint c = CGPointMake(p.normalizedPosition.x * sb.size.width,
                            p.normalizedPosition.y * sb.size.height);
    self.center = c;
    CGRect f = self.frame;
    f.origin = [self _clampOrigin:f.origin size:f.size];
    self.frame = f;
}

#pragma mark - 动作

- (void)_gearTapped { [self _openSettings]; }
- (void)_openSettings { if (self.onOpenSettings) self.onOpenSettings(); }

// 触摸穿透：若开启则本视图不拦截任何触摸
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([QFPrefs shared].passthrough) return NO;
    return [super pointInside:point withEvent:event];
}

@end