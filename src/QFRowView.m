//
//  QFRowView.m
//  QFMonitor — 按参考图实现的半透明圆角悬浮条
//

#import "QFRowView.h"
#import "QFMetrics.h"
#import "QFPrefs.h"

@interface QFRowView ()
@property (nonatomic, strong) UILabel   *metricsLabel;
@property (nonatomic, strong) UIButton  *gearButton;
@property (nonatomic, strong) UIView    *capsuleView;
@property (nonatomic, assign) CGPoint   dragStartCenter;
@property (nonatomic, assign) CGFloat   currentFontSize;
@end

@implementation QFRowView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = YES;

        _capsuleView = [[UIView alloc] initWithFrame:CGRectZero];
        _capsuleView.backgroundColor = [UIColor colorWithWhite:0.015 alpha:0.78];
        _capsuleView.layer.cornerRadius = 14.0;
        _capsuleView.layer.masksToBounds = YES;
        [self addSubview:_capsuleView];

        _metricsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _metricsLabel.numberOfLines = 0;
        _metricsLabel.lineBreakMode = NSLineBreakByCharWrapping;
        _metricsLabel.backgroundColor = [UIColor clearColor];
        _metricsLabel.textAlignment = NSTextAlignmentLeft;
        [_capsuleView addSubview:_metricsLabel];

        _gearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _gearButton.backgroundColor = [UIColor clearColor];
        _gearButton.adjustsImageWhenHighlighted = NO;
        [_gearButton addTarget:self action:@selector(onGear) forControlEvents:UIControlEventTouchUpInside];
        [_capsuleView addSubview:_gearButton];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *dbl = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGear)];
        dbl.numberOfTapsRequired = 2;
        [self addGestureRecognizer:dbl];

        [self applyPrefs];
    }
    return self;
}

#pragma mark - 富文本

- (NSString *)buildTextPlain {
    QFPrefs *p = [QFPrefs shared];
    QFMetrics *m = [QFMetrics shared];
    NSMutableArray<NSString *> *segs = [NSMutableArray array];
    if (p.showCPU) [segs addObject:[NSString stringWithFormat:@"CPU %.0f%%", m.cpuPercent]];
    if (p.showFPS) [segs addObject:[NSString stringWithFormat:@"FPS %.0f", m.fps]];
    if (p.showUp) [segs addObject:[NSString stringWithFormat:@"上传↑ %@", [QFMetrics formatRate:m.upBps]]];
    if (p.showDown) [segs addObject:[NSString stringWithFormat:@"下载↓ %@", [QFMetrics formatRate:m.downBps]]];
    if (p.showBattery) [segs addObject:[NSString stringWithFormat:@"电池 %d%%%@", m.batteryPercent, m.charging ? @"⚡" : @""]];
    if (p.showCurrent) {
        NSString *v = m.currentValid ? [NSString stringWithFormat:@"%ldmA", (long)lround(m.currentMa)] : @"--mA";
        [segs addObject:[@"电流 " stringByAppendingString:v]];
    }
    if (p.showPower) {
        NSString *v = m.wattValid ? [NSString stringWithFormat:@"%.1fW", m.watt] : @"--W";
        [segs addObject:[@"瓦数 " stringByAppendingString:v]];
    }
    if (p.showTemp) {
        NSString *v = m.temperatureC > -100.0 ? [NSString stringWithFormat:@"%.0f°C", m.temperatureC] : @"--°C";
        [segs addObject:[@"温度 " stringByAppendingString:v]];
    }
    NSString *s = [segs componentsJoinedByString:@"  "];
    if ([QFPrefs shared].locked) s = s.length ? [s stringByAppendingString:@"  🔒"] : @"🔒";
    return s.length ? s : @"QFMonitor";
}

- (UIColor *)colorFor:(NSInteger)i {
    NSArray *c = @[
        [UIColor colorWithRed:0.30 green:0.79 blue:0.96 alpha:1.0],
        [UIColor colorWithRed:0.65 green:0.55 blue:0.98 alpha:1.0],
        [UIColor colorWithRed:0.20 green:0.83 blue:0.60 alpha:1.0],
        [UIColor colorWithRed:0.98 green:0.75 blue:0.14 alpha:1.0],
        [UIColor colorWithRed:0.96 green:0.45 blue:0.71 alpha:1.0],
        [UIColor colorWithRed:0.98 green:0.44 blue:0.52 alpha:1.0],
        [UIColor colorWithRed:0.98 green:0.57 blue:0.24 alpha:1.0],
        [UIColor colorWithRed:0.97 green:0.44 blue:0.44 alpha:1.0],
    ];
    return c[MIN(MAX(i, 0), 7)];
}

- (NSAttributedString *)att:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[NSFontAttributeName] = font;
    d[NSForegroundColorAttributeName] = color ?: UIColor.whiteColor;
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithWhite:0 alpha:0.95];
    shadow.shadowBlurRadius = 1.15;
    shadow.shadowOffset = CGSizeZero;
    d[NSShadowAttributeName] = shadow;
    return [[NSAttributedString alloc] initWithString:text ?: @"" attributes:d];
}

- (NSAttributedString *)buildTextWithFontSize:(CGFloat)fontSize {
    QFPrefs *p = [QFPrefs shared];
    QFMetrics *m = [QFMetrics shared];
    CGFloat fs = MAX(6.0, MIN(46.0, fontSize));
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:fs weight:UIFontWeightSemibold];
    NSMutableArray *parts = [NSMutableArray array];

    if (p.showCPU) {
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"CPU " font:font color:[self colorFor:0]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%.0f%%", m.cpuPercent] font:font color:[self colorFor:0]]];
        [parts addObject:a];
    }
    if (p.showFPS) {
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"FPS " font:font color:[self colorFor:1]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%.0f", m.fps] font:font color:[self colorFor:1]]];
        [parts addObject:a];
    }
    if (p.showUp) {
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"上传↑ " font:font color:[self colorFor:2]]];
        [a appendAttributedString:[self att:[QFMetrics formatRate:m.upBps] font:font color:[self colorFor:2]]];
        [parts addObject:a];
    }
    if (p.showDown) {
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"下载↓ " font:font color:[self colorFor:3]]];
        [a appendAttributedString:[self att:[QFMetrics formatRate:m.downBps] font:font color:[self colorFor:3]]];
        [parts addObject:a];
    }
    if (p.showBattery) {
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"电池 " font:font color:[self colorFor:4]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%d%%%@", m.batteryPercent, m.charging ? @"⚡" : @""] font:font color:[self colorFor:4]]];
        [parts addObject:a];
    }
    if (p.showCurrent) {
        NSString *v = m.currentValid ? [NSString stringWithFormat:@"%ldmA", (long)lround(m.currentMa)] : @"--mA";
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"电流 " font:font color:[self colorFor:5]]];
        [a appendAttributedString:[self att:v font:font color:[self colorFor:5]]];
        [parts addObject:a];
    }
    if (p.showPower) {
        NSString *v = m.wattValid ? [NSString stringWithFormat:@"%.1fW", m.watt] : @"--W";
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"瓦数 " font:font color:[self colorFor:6]]];
        [a appendAttributedString:[self att:v font:font color:[self colorFor:6]]];
        [parts addObject:a];
    }
    if (p.showTemp) {
        NSString *v = m.temperatureC > -100.0 ? [NSString stringWithFormat:@"%.0f°C", m.temperatureC] : @"--°C";
        NSMutableAttributedString *a = [NSMutableAttributedString new];
        [a appendAttributedString:[self att:@"温度 " font:font color:[self colorFor:7]]];
        [a appendAttributedString:[self att:v font:font color:[self colorFor:7]]];
        [parts addObject:a];
    }

    NSMutableAttributedString *out = [NSMutableAttributedString new];
    for (NSInteger i = 0; i < (NSInteger)parts.count; i++) {
        if (i) [out appendAttributedString:[self att:@"  " font:font color:UIColor.whiteColor]];
        [out appendAttributedString:parts[i]];
    }
    if (p.locked) {
        if (out.length) [out appendAttributedString:[self att:@"  " font:font color:UIColor.whiteColor]];
        [out appendAttributedString:[self att:@"🔒" font:font color:[self colorFor:3]]];
    }
    if (!out.length) [out appendAttributedString:[self att:@"QFMonitor" font:font color:[self colorFor:0]]];
    return out;
}

- (void)rebuildTextWithFontSize:(CGFloat)fs constrainedToWidth:(CGFloat)width {
    NSMutableAttributedString *text = [[self buildTextWithFontSize:fs] mutableCopy];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByCharWrapping;
    style.alignment = NSTextAlignmentLeft;
    style.lineSpacing = 0.0;
    [text addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, text.length)];
    self.metricsLabel.attributedText = text;
    self.metricsLabel.preferredMaxLayoutWidth = width;
    self.metricsLabel.numberOfLines = 0;
    self.metricsLabel.lineBreakMode = NSLineBreakByCharWrapping;
}

#pragma mark - 刷新与布局

- (void)refreshText { [self refreshTextConstrainedToWidth:CGFLOAT_MAX]; }

- (void)refreshTextConstrainedToWidth:(CGFloat)maxWidth {
    if (maxWidth <= 1.0) maxWidth = CGFLOAT_MAX;
    [self relayoutConstrainedToWidth:maxWidth];
}

- (void)applyPrefs {
    QFPrefs *p = [QFPrefs shared];
    self.currentFontSize = MAX(6.0, MIN(46.0, p.fontSize * p.scale));
    [self configureGearForSize:self.currentFontSize];
    CGFloat w = CGRectGetWidth(self.window.bounds);
    [self refreshTextConstrainedToWidth:(w > 0 ? w - 16.0 : CGFLOAT_MAX)];
}

- (void)configureGearForSize:(CGFloat)fs {
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:MAX(8.0, fs * 0.95) weight:UIImageSymbolWeightSemibold];
    UIImage *image = [UIImage systemImageNamed:@"gearshape.fill" withConfiguration:cfg];
    if (image) [self.gearButton setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.gearButton.tintColor = [UIColor colorWithWhite:1.0 alpha:0.72];
}

- (void)relayout { [self relayoutConstrainedToWidth:CGFLOAT_MAX]; }

- (void)relayoutConstrainedToWidth:(CGFloat)maxWidth {
    if (maxWidth <= 1.0) maxWidth = CGFLOAT_MAX;
    CGFloat fs = self.currentFontSize > 0 ? self.currentFontSize : MAX(6.0, [QFPrefs shared].fontSize * [QFPrefs shared].scale);
    CGFloat horizontal = MAX(7.0, fs * 0.62);
    CGFloat vertical = MAX(5.0, fs * 0.42);
    CGFloat gearSize = MAX(10.0, fs * 0.95);
    CGFloat gearGap = MAX(4.0, fs * 0.40);
    CGFloat innerMax = maxWidth == CGFLOAT_MAX ? CGFLOAT_MAX : MAX(40.0, maxWidth - horizontal * 2.0 - gearSize - gearGap);

    [self rebuildTextWithFontSize:fs constrainedToWidth:innerMax];
    CGSize ms = [self.metricsLabel sizeThatFits:CGSizeMake(innerMax, CGFLOAT_MAX)];
    ms.width = ceil(MIN(ms.width, innerMax));
    ms.height = ceil(MAX(ms.height, fs));

    CGFloat totalW = ms.width + horizontal * 2.0 + gearGap + gearSize;
    CGFloat totalH = ms.height + vertical * 2.0;
    if (maxWidth != CGFLOAT_MAX) totalW = MIN(totalW, maxWidth);
    totalW = MAX(totalW, gearSize + horizontal * 2.0 + 24.0);
    totalH = MAX(totalH, gearSize + vertical * 2.0);

    CGPoint oldCenter = self.center;
    self.bounds = CGRectMake(0, 0, ceil(totalW), ceil(totalH));
    self.center = oldCenter;
    self.capsuleView.frame = self.bounds;
    self.capsuleView.layer.cornerRadius = MIN(16.0, totalH / 2.0);

    self.metricsLabel.frame = CGRectMake(horizontal, vertical, MIN(ms.width, totalW - horizontal * 2.0 - gearGap - gearSize), ms.height);
    self.gearButton.frame = CGRectMake(totalW - horizontal - gearSize, (totalH - gearSize) / 2.0, gearSize, gearSize);
}

#pragma mark - 交互

- (void)onGear {
    if ([self.delegate respondsToSelector:@selector(rowViewDidTapSettings:)]) [self.delegate rowViewDidTapSettings:self];
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *sup = self.superview;
    if (!sup) return;
    QFPrefs *p = [QFPrefs shared];
    if (p.locked || !p.freeDrag) {
        if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) [g setTranslation:CGPointZero inView:sup];
        return;
    }
    if (g.state == UIGestureRecognizerStateBegan) self.dragStartCenter = self.center;
    CGPoint t = [g translationInView:sup];
    CGPoint c = CGPointMake(self.dragStartCenter.x + t.x, self.dragStartCenter.y + t.y);
    CGRect b = sup.bounds;
    CGFloat hw = CGRectGetWidth(self.bounds) / 2.0;
    CGFloat hh = CGRectGetHeight(self.bounds) / 2.0;
    c.x = MAX(hw + 1.0, MIN(CGRectGetWidth(b) - hw - 1.0, c.x));
    c.y = MAX(hh + 1.0, MIN(CGRectGetHeight(b) - hh - 1.0, c.y));
    self.center = c;
    if ([self.delegate respondsToSelector:@selector(rowView:didDragToCenter:)]) [self.delegate rowView:self didDragToCenter:c];
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        if ([self.delegate respondsToSelector:@selector(rowViewDidEndDragging:)]) [self.delegate rowViewDidEndDragging:self];
    }
}

@end
