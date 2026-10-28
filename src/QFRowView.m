//
//  QFRowView.m
//

#import "QFRowView.h"
#import "QFMetrics.h"
#import "QFPrefs.h"

@interface QFRowView ()
@property (nonatomic, strong) UILabel   *metricsLabel;
@property (nonatomic, strong) UIButton  *gearButton;
@property (nonatomic, assign) CGPoint   dragStartCenter;
@property (nonatomic, assign) CGFloat   currentFontSize;
@end

@implementation QFRowView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 彻底无背景
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.layer.borderWidth = 0;
        self.layer.cornerRadius = 0;
        self.layer.shadowOpacity = 0;
        self.userInteractionEnabled = YES;

        _metricsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _metricsLabel.numberOfLines = 1;
        _metricsLabel.lineBreakMode = NSLineBreakByClipping;
        _metricsLabel.backgroundColor = [UIColor clearColor];
        _metricsLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_metricsLabel];

        _gearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _gearButton.backgroundColor = [UIColor clearColor];
        _gearButton.adjustsImageWhenHighlighted = NO;
        [_gearButton addTarget:self
                        action:@selector(onGear)
              forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_gearButton];

        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        [self addGestureRecognizer:pan];

        UITapGestureRecognizer *dbl =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onGear)];
        dbl.numberOfTapsRequired = 2;
        [self addGestureRecognizer:dbl];

        [self applyPrefs];
    }
    return self;
}

#pragma mark - 配色

+ (NSArray<UIColor *> *)accentPalette {
    return @[
        [UIColor colorWithRed:0.36 green:0.86 blue:1.00 alpha:1.0],   // 0 青
        [UIColor colorWithRed:0.40 green:0.90 blue:0.60 alpha:1.0],   // 1 绿
        [UIColor colorWithRed:1.00 green:0.70 blue:0.32 alpha:1.0],   // 2 橙
        [UIColor colorWithRed:0.72 green:0.60 blue:1.00 alpha:1.0],   // 3 紫
        [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0],   // 4 白
        [UIColor colorWithRed:1.00 green:0.52 blue:0.74 alpha:1.0],   // 5 粉
    ];
}

+ (UIColor *)dimColor {
    return [UIColor colorWithWhite:1.0 alpha:0.55];
}

+ (UIColor *)hotColor {
    return [UIColor colorWithRed:1.00 green:0.42 blue:0.42 alpha:1.0];
}

#pragma mark - 文字构建

- (NSAttributedString *)buildText {
    return [self buildTextWithFontSize:self.currentFontSize];
}

- (NSString *)buildTextPlain {
    QFPrefs *p = [QFPrefs shared];
    QFMetrics *m = [QFMetrics shared];
    NSMutableArray<NSString *> *segs = [NSMutableArray array];

    if (p.showCPU)   [segs addObject:[NSString stringWithFormat:@"CPU %.0f%%", m.cpuPercent]];
    if (p.showFPS)   [segs addObject:[NSString stringWithFormat:@"FPS %.0f", m.fps]];
    if (p.showUp)    [segs addObject:[NSString stringWithFormat:@"上传↑ %@", [QFMetrics formatRate:m.upBps]]];
    if (p.showDown)  [segs addObject:[NSString stringWithFormat:@"下载↓ %@", [QFMetrics formatRate:m.downBps]]];
    if (p.showBattery)
        [segs addObject:[NSString stringWithFormat:@"电池 %d%%%@", m.batteryPercent, m.charging ? @"⚡" : @""]];
    if (p.showCurrent) {
        NSString *c = m.currentValid ? [NSString stringWithFormat:@"%ldmA", (long)lround(m.currentMa)] : @"--mA";
        [segs addObject:[@"电流 " stringByAppendingString:c]];
    }
    if (p.showPower) {
        NSString *w = m.wattValid ? [NSString stringWithFormat:@"%.1fW", m.watt] : @"--W";
        [segs addObject:[@"瓦数 " stringByAppendingString:w]];
    }
    if (p.showTemp) {
        NSString *t = (m.temperatureC > -100.0) ? [NSString stringWithFormat:@"%.0f°C", m.temperatureC] : @"--°C";
        [segs addObject:[@"温度 " stringByAppendingString:t]];
    }

    NSMutableString *s = [[segs componentsJoinedByString:@"  "] mutableCopy];
    if (p.locked) {
        if (s.length) [s appendString:@"  "];
        [s appendString:@"🔒"];
    }
    if (s.length == 0) s = [@"QFMonitor" mutableCopy];
    return s;
}

- (void)rebuildTextWithFontSize:(CGFloat)fs {
    self.metricsLabel.attributedText = [self buildTextWithFontSize:fs];
}

- (NSAttributedString *)buildTextWithFontSize:(CGFloat)fontSize {
    QFPrefs *p = [QFPrefs shared];
    QFMetrics *m = [QFMetrics shared];

    CGFloat fs = fontSize;
    if (fs < 6.0) fs = 6.0;
    if (fs > 46.0) fs = 46.0;

    UIFont *nf = [UIFont monospacedDigitSystemFontOfSize:fs
                                                  weight:UIFontWeightSemibold];
    UIColor *white = [UIColor whiteColor];

    NSMutableArray *segs = [NSMutableArray array];

    // CPU → FPS → 上传↑ → 下载↓ → 电池 → 电流 → 瓦数 → 温度
    if (p.showCPU) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"CPU " font:nf color:[self colorFor:0]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%.0f%%", m.cpuPercent] font:nf color:[self colorFor:0]]];
        [segs addObject:a];
    }
    if (p.showFPS) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"FPS " font:nf color:[self colorFor:1]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%.0f", m.fps] font:nf color:[self colorFor:1]]];
        [segs addObject:a];
    }
    if (p.showUp) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"上传↑ " font:nf color:[self colorFor:2]]];
        [a appendAttributedString:[self att:[QFMetrics formatRate:m.upBps] font:nf color:[self colorFor:2]]];
        [segs addObject:a];
    }
    if (p.showDown) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"下载↓ " font:nf color:[self colorFor:3]]];
        [a appendAttributedString:[self att:[QFMetrics formatRate:m.downBps] font:nf color:[self colorFor:3]]];
        [segs addObject:a];
    }
    if (p.showBattery) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"电池 " font:nf color:[self colorFor:4]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%d%%%@", m.batteryPercent, m.charging ? @"⚡" : @""] font:nf color:[self colorFor:4]]];
        [segs addObject:a];
    }
    if (p.showCurrent) {
        NSString *c = m.currentValid ? [NSString stringWithFormat:@"%ldmA", (long)lround(m.currentMa)] : @"--mA";
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"电流 " font:nf color:[self colorFor:5]]];
        [a appendAttributedString:[self att:c font:nf color:[self colorFor:5]]];
        [segs addObject:a];
    }
    if (p.showPower) {
        NSString *w = m.wattValid ? [NSString stringWithFormat:@"%.1fW", m.watt] : @"--W";
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"瓦数 " font:nf color:[self colorFor:6]]];
        [a appendAttributedString:[self att:w font:nf color:[self colorFor:6]]];
        [segs addObject:a];
    }
    if (p.showTemp) {
        NSString *t = (m.temperatureC > -100.0) ? [NSString stringWithFormat:@"%.0f°C", m.temperatureC] : @"--°C";
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"温度 " font:nf color:[self colorFor:7]]];
        [a appendAttributedString:[self att:t font:nf color:[self colorFor:7]]];
        [segs addObject:a];
    }

    NSMutableAttributedString *out = [[NSMutableAttributedString alloc] init];
    for (NSInteger i = 0; i < (NSInteger)segs.count; i++) {
        if (i > 0) [out appendAttributedString:[self att:@"  " font:nf color:white]];
        [out appendAttributedString:segs[i]];
    }
    if (p.locked) {
        if (out.length) [out appendAttributedString:[self att:@"  " font:nf color:white]];
        [out appendAttributedString:[self att:@"🔒" font:nf color:[self colorFor:3]]];
    }
    if (!out.length) {
        out = [[NSMutableAttributedString alloc] initWithAttributedString:[self att:@"QFMonitor" font:nf color:[self colorFor:0]]];
    }
    return out;
}

// 8 种颜色: CPU青 / FPS紫 / 上传绿 / 下载琥珀 / 电池粉 / 电流玫红 / 瓦数橙 / 温度红
- (UIColor *)colorFor:(NSInteger)i {
    NSArray *c = @[
        [UIColor colorWithRed:0.30 green:0.79 blue:0.96 alpha:1.0], // 0 CPU 青
        [UIColor colorWithRed:0.65 green:0.55 blue:0.98 alpha:1.0], // 1 FPS 紫
        [UIColor colorWithRed:0.20 green:0.83 blue:0.60 alpha:1.0], // 2 上传 绿
        [UIColor colorWithRed:0.98 green:0.75 blue:0.14 alpha:1.0], // 3 下载 琥珀
        [UIColor colorWithRed:0.96 green:0.45 blue:0.71 alpha:1.0], // 4 电池 粉
        [UIColor colorWithRed:0.98 green:0.44 blue:0.52 alpha:1.0], // 5 电流 玫红
        [UIColor colorWithRed:0.98 green:0.57 blue:0.24 alpha:1.0], // 6 瓦数 橙
        [UIColor colorWithRed:0.97 green:0.44 blue:0.44 alpha:1.0], // 7 温度 红
    ];
    return c[MIN(MAX(i, 0), 7)];
}

- (NSAttributedString *)att:(NSString *)t font:(UIFont *)f color:(UIColor *)c {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (f) d[NSFontAttributeName] = f;
    d[NSForegroundColorAttributeName] = c ?: [UIColor whiteColor];
    // 极紧的文字描边感(blur 1.2, 零偏移), 只为在浅色壁纸上也能看清,
    // 不会形成任何"底色"。
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    sh.shadowBlurRadius = 1.2;
    sh.shadowOffset = CGSizeZero;
    d[NSShadowAttributeName] = sh;
    return [[NSAttributedString alloc] initWithString:(t ?: @"") attributes:d];
}

#pragma mark - 刷新

- (void)refreshText {
    [self refreshTextConstrainedToWidth:CGFLOAT_MAX];
}

- (void)refreshTextConstrainedToWidth:(CGFloat)maxWidth {
    if (maxWidth <= 1.0) maxWidth = CGFLOAT_MAX;
    // 先按当前字号估算, 若超宽就在 relayout 里缩
    self.metricsLabel.attributedText = [self buildTextWithFontSize:self.currentFontSize];
    [self relayoutConstrainedToWidth:maxWidth];
}

- (void)applyPrefs {
    QFPrefs *p = [QFPrefs shared];

    CGFloat fs = p.fontSize * p.scale;
    if (fs < 6.0) fs = 6.0;
    if (fs > 46.0) fs = 46.0;
    self.currentFontSize = fs;

    UIColor *accent = [[self class] accentPalette][MIN(MAX(p.accent, 0), 5)];

    [self configureGearForSize:fs];

    CGFloat w = CGRectGetWidth(self.window.bounds);
    [self refreshTextConstrainedToWidth:(w > 0 ? w - 16.0 : CGFLOAT_MAX)];
}

- (void)configureGearForSize:(CGFloat)fs {
    QFPrefs *p = [QFPrefs shared];
    UIColor *accent = [[self class] accentPalette][MIN(MAX(p.accent, 0), 5)];

    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:fs * 0.95
                                                         weight:UIImageSymbolWeightSemibold];
    UIImage *img = [UIImage systemImageNamed:@"gearshape"
                       withConfiguration:cfg];
    if (img) {
        [self.gearButton setImage:[img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                         forState:UIControlStateNormal];
    }
    self.gearButton.tintColor = accent;
}

- (void)relayout {
    [self relayoutConstrainedToWidth:CGFLOAT_MAX];
}

// 在给定最大宽度内布局: 文字放不下时按比例缩字号(最低 5pt)
- (void)relayoutConstrainedToWidth:(CGFloat)maxWidth {
    if (maxWidth <= 1.0) maxWidth = CGFLOAT_MAX;

    CGFloat fs = self.currentFontSize;

    NSString *plain = [self buildTextPlain];
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:fs weight:UIFontWeightSemibold];

    CGFloat gearSize = MAX(8.0, fs * 0.95);
    CGFloat gap = MAX(3.0, fs * 0.45);
    CGFloat avail = maxWidth - gap - gearSize;
    if (avail < 20.0) avail = maxWidth;   // 极限情况: 只保证不越界

    CGSize measured = [plain sizeWithAttributes:@{NSFontAttributeName: font}];
    if (maxWidth != CGFLOAT_MAX && measured.width > avail && measured.width > 0) {
        CGFloat scaled = fs * (avail / measured.width);
        if (scaled < 5.0) scaled = 5.0;
        if (scaled < fs) {
            fs = scaled;
            font = [UIFont monospacedDigitSystemFontOfSize:fs weight:UIFontWeightSemibold];
            [self configureGearForSize:fs];
            gearSize = MAX(8.0, fs * 0.95);
            gap = MAX(3.0, fs * 0.45);
            measured = [plain sizeWithAttributes:@{NSFontAttributeName: font}];
        }
    }

    // 用最终字号重建富文本(颜色分段)
    [self rebuildTextWithFontSize:fs];

    CGSize ms = [self.metricsLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    ms.width = ceil(ms.width);
    ms.height = ceil(ms.height);

    CGSize total = CGSizeMake(ms.width + gap + gearSize, MAX(ms.height, gearSize));
    // 最后一道保险: 总宽不超过 maxWidth
    if (maxWidth != CGFLOAT_MAX && total.width > maxWidth) {
        total.width = maxWidth;
    }

    self.metricsLabel.frame = CGRectMake(0, (total.height - ms.height) / 2.0,
                                         MIN(ms.width, total.width), ms.height);
    self.gearButton.frame = CGRectMake(MAX(0.0, total.width - gearSize),
                                       (total.height - gearSize) / 2.0,
                                       gearSize, gearSize);

    // 保持中心不变
    CGPoint c = self.center;
    self.bounds = CGRectMake(0, 0, total.width, total.height);
    self.center = c;
}

#pragma mark - 手势

- (void)onGear {
    if ([self.delegate respondsToSelector:@selector(rowViewDidTapSettings:)]) {
        [self.delegate rowViewDidTapSettings:self];
    }
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *sup = self.superview;
    if (!sup) return;

    QFPrefs *p = [QFPrefs shared];
    // 锁定位置 或 关闭自由移动 → 拖动无效
    if (p.locked || !p.freeDrag) {
        if (g.state == UIGestureRecognizerStateEnded ||
            g.state == UIGestureRecognizerStateCancelled) {
            [g setTranslation:CGPointZero inView:sup];
        }
        return;
    }

    if (g.state == UIGestureRecognizerStateBegan) {
        self.dragStartCenter = self.center;
    }

    CGPoint t = [g translationInView:sup];
    CGPoint c = CGPointMake(self.dragStartCenter.x + t.x,
                             self.dragStartCenter.y + t.y);

    // 限制在父视图内
    CGRect b = sup.bounds;
    CGFloat hw = CGRectGetWidth(self.bounds) / 2.0;
    CGFloat hh = CGRectGetHeight(self.bounds) / 2.0;
    if (c.x < hw) c.x = hw;
    if (c.x > CGRectGetWidth(b) - hw) c.x = CGRectGetWidth(b) - hw;
    if (c.y < hh) c.y = hh;
    if (c.y > CGRectGetHeight(b) - hh) c.y = CGRectGetHeight(b) - hh;

    self.center = c;

    if ([self.delegate respondsToSelector:@selector(rowView:didDragToCenter:)]) {
        [self.delegate rowView:self didDragToCenter:c];
    }
    if (g.state == UIGestureRecognizerStateEnded ||
        g.state == UIGestureRecognizerStateCancelled) {
        if ([self.delegate respondsToSelector:@selector(rowViewDidEndDragging:)]) {
            [self.delegate rowViewDidEndDragging:self];
        }
    }
}

@end
