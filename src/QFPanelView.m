//
//  QFPanelView.m
//  QFMonitor — 参考图同款深色设置面板
//

#import "QFPanelView.h"
#import "QFPrefs.h"
#import "QFMetrics.h"

#define QFPMargin 16.0

@interface QFPanelView ()
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *content;
@property (nonatomic, strong) UILabel *previewLabel;
@property (nonatomic, strong) UILabel *fontValueLabel;
@property (nonatomic, strong) UILabel *scaleValueLabel;
@property (nonatomic, strong) UISlider *fontSlider;
@property (nonatomic, strong) UISlider *scaleSlider;
@property (nonatomic, strong) NSMutableArray *switches;
@property (nonatomic, strong) UIView *handle;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, assign) CGFloat contentWidth;
@end

@implementation QFPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        self.switches = [NSMutableArray array];
        [self buildUI];
    }
    return self;
}

+ (UIColor *)cyan { return [UIColor colorWithRed:0.10 green:0.72 blue:0.91 alpha:1.0]; }
+ (UIColor *)panelBg { return [UIColor colorWithRed:0.105 green:0.108 blue:0.115 alpha:0.985]; }
+ (UIColor *)rowBg { return [UIColor colorWithWhite:1.0 alpha:0.075]; }
+ (UIColor *)divider { return [UIColor colorWithWhite:1.0 alpha:0.075]; }
+ (UIColor *)muted { return [UIColor colorWithWhite:1.0 alpha:0.52]; }
+
+- (void)buildUI {
    CGFloat W = CGRectGetWidth(self.bounds) > 0 ? CGRectGetWidth(self.bounds) : 390.0;
    self.contentWidth = W - 2.0 * QFPMargin;

    _card = [[UIView alloc] initWithFrame:CGRectZero];
    _card.backgroundColor = [QFPanelView panelBg];
    _card.layer.cornerRadius = 22.0;
    _card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    _card.layer.masksToBounds = YES;
    [self addSubview:_card];

    _handle = [[UIView alloc] initWithFrame:CGRectZero];
    _handle.backgroundColor = [UIColor colorWithWhite:1 alpha:0.22];
    _handle.layer.cornerRadius = 2.5;
    [_card addSubview:_handle];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text = @"QFSpeed";
    _titleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    _titleLabel.textColor = UIColor.whiteColor;
    [_card addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _subtitleLabel.text = @"网速 · 性能 · 电量";
    _subtitleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    _subtitleLabel.textColor = [QFPanelView muted];
    [_card addSubview:_subtitleLabel];

    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _closeButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    _closeButton.layer.cornerRadius = 16.0;
    [_closeButton setTitle:@"×" forState:UIControlStateNormal];
    _closeButton.titleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightRegular];
    [_closeButton setTitleColor:[QFPanelView muted] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [_card addSubview:_closeButton];

    _scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scroll.showsVerticalScrollIndicator = NO;
    _scroll.alwaysBounceVertical = YES;
    _scroll.backgroundColor = UIColor.clearColor;
    [_card addSubview:_scroll];
    _content = [[UIView alloc] initWithFrame:CGRectZero];
    [_scroll addSubview:_content];
    [self buildContent];
}

- (void)buildContent {
    [_content.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.switches removeAllObjects];
    CGFloat W = self.contentWidth;
    CGFloat y = 0.0;

    UILabel *info = [self textLabel:@"挂载 host  UIWindow  lv=0  自愈0" size:11 color:[UIColor colorWithWhite:1 alpha:0.30]];
    info.frame = CGRectMake(QFPMargin, y, W, 20); [_content addSubview:info]; y += 27;

    // 第一段：显示项目
    NSArray *names = @[@"CPU 占用", @"FPS 帧率", @"上传速度 ↑", @"下载速度 ↓", @"电池 · 电流 · 瓦数 · 温度"];
    NSArray *keys = @[@"showCPU", @"showFPS", @"showUp", @"showDown", @"showBattery"];
    UILabel *showCaption = [self sectionLabel:@"显示项目"]; showCaption.frame = CGRectMake(QFPMargin, y, W, 22); [_content addSubview:showCaption]; y += 25;
    CGFloat rowH = 46.0;
    UIView *showBox = [self boxWithFrame:CGRectMake(QFPMargin, y, W, rowH * names.count)]; [_content addSubview:showBox];
    for (NSInteger i = 0; i < names.count; i++) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, i * rowH, W, rowH)]; [showBox addSubview:row];
        UILabel *l = [self textLabel:names[i] size:15 color:UIColor.whiteColor]; l.frame = CGRectMake(10, 0, W - 78, rowH); [row addSubview:l];
        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero]; sw.onTintColor = [QFPanelView cyan]; sw.on = [self boolForKey:keys[i]]; sw.tag = i; [sw addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged]; [row addSubview:sw]; [self layoutSwitch:sw inRow:row]; [self.switches addObject:sw];
        if (i < names.count - 1) { UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, rowH - 0.5, W - 20, 0.5)]; line.backgroundColor = [QFPanelView divider]; [row addSubview:line]; }
    }
    y += rowH * names.count + 15;

    // 第二段：外观
    UILabel *appearance = [self sectionLabel:@"外观"]; appearance.frame = CGRectMake(QFPMargin, y, W, 22); [_content addSubview:appearance]; y += 26;
    _fontValueLabel = [self valueLabel]; _fontValueLabel.frame = CGRectMake(W - 68, y, 58, 22); [_content addSubview:_fontValueLabel];
    UILabel *fontText = [self textLabel:@"字体大小" size:14 color:UIColor.whiteColor]; fontText.frame = CGRectMake(QFPMargin, y, 100, 22); [_content addSubview:fontText]; y += 24;
    _fontSlider = [self slider]; _fontSlider.minimumValue = 8; _fontSlider.maximumValue = 24; _fontSlider.frame = CGRectMake(QFPMargin, y, W, 32); [_fontSlider addTarget:self action:@selector(onFontSlider) forControlEvents:UIControlEventValueChanged]; [_content addSubview:_fontSlider]; y += 45;
    _scaleValueLabel = [self valueLabel]; _scaleValueLabel.frame = CGRectMake(W - 72, y, 62, 22); [_content addSubview:_scaleValueLabel];
    UILabel *scaleText = [self textLabel:@"整体缩放" size:14 color:UIColor.whiteColor]; scaleText.frame = CGRectMake(QFPMargin, y, 100, 22); [_content addSubview:scaleText]; y += 24;
    _scaleSlider = [self slider]; _scaleSlider.minimumValue = 0.6; _scaleSlider.maximumValue = 2.0; _scaleSlider.frame = CGRectMake(QFPMargin, y, W, 32); [_scaleSlider addTarget:self action:@selector(onScaleSlider) forControlEvents:UIControlEventValueChanged]; [_content addSubview:_scaleSlider]; y += 49;

    // 第三段：位置调节九宫格
    UILabel *position = [self sectionLabel:@"位置调节"]; position.frame = CGRectMake(QFPMargin, y, W, 22); [_content addSubview:position]; y += 27;
    CGFloat gap = 6.0; CGFloat gw = (W - gap * 2) / 3.0; CGFloat gh = 53.0;
    NSArray *grid = @[@"↖", @"↑", @"↗", @"←", @"中心", @"→", @"↙", @"↓", @"↘"];
    for (NSInteger i = 0; i < 9; i++) {
        NSInteger col = i % 3, row = i / 3;
        UIButton *b = [self actionButton:grid[i] frame:CGRectMake(QFPMargin + col * (gw + gap), y + row * (gh + gap), gw, gh)]; b.tag = 300 + i; [b addTarget:self action:@selector(onGrid:) forControlEvents:UIControlEventTouchUpInside]; [_content addSubview:b];
        if (i == 4) { b.backgroundColor = [QFPanelView cyan]; [b setTitleColor:UIColor.blackColor forState:UIControlStateNormal]; }
    }
    y += 3 * gh + 2 * gap + 9;
    NSArray *nudges = @[@"◀ 微调", @"▲ 上移", @"▼ 下移", @"▶ 微调"]; CGFloat nw = (W - gap * 3) / 4.0; CGFloat nh = 38.0;
    for (NSInteger i = 0; i < 4; i++) { UIButton *b = [self actionButton:nudges[i] frame:CGRectMake(QFPMargin + i * (nw + gap), y, nw, nh)]; b.tag = 320 + i; b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]; [b addTarget:self action:@selector(onNudge:) forControlEvents:UIControlEventTouchUpInside]; [_content addSubview:b]; }
    y += nh + 13;

    // 第四段：自由移动与锁定
    [self miscSwitchRow:@"自由移动（拖动）" key:@"freeDrag" tag:401 y:y]; y += 46;
    [self miscSwitchRow:@"🔒 锁定位置" key:@"locked" tag:402 y:y]; y += 46;

    // 第五段：操作按钮
    CGFloat bw = (W - 10) / 2.0;
    UIButton *reset = [self actionButton:@"重置位置" frame:CGRectMake(QFPMargin, y, bw, 42)]; [reset addTarget:self action:@selector(onResetPosition) forControlEvents:UIControlEventTouchUpInside]; [_content addSubview:reset];
    UIButton *edge = [self actionButton:@"贴边隐藏" frame:CGRectMake(QFPMargin + bw + 10, y, bw, 42)]; [edge addTarget:self action:@selector(onEdgeHide) forControlEvents:UIControlEventTouchUpInside]; [_content addSubview:edge]; y += 52;
    UIButton *hide = [self actionButton:@"隐藏悬浮窗" frame:CGRectMake(QFPMargin, y, bw, 42)]; [hide addTarget:self action:@selector(onHideHUD) forControlEvents:UIControlEventTouchUpInside]; [_content addSubview:hide];
    UIButton *close = [self actionButton:@"关闭面板" frame:CGRectMake(QFPMargin + bw + 10, y, bw, 42)]; [close addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside]; [_content addSubview:close]; y += 56;
    UILabel *hint = [self textLabel:@"「锁定位置」开启后悬浮条无法拖动，只能靠位置按钮/微调移动；关闭后可直接拖动。" size:10 color:[UIColor colorWithWhite:1 alpha:0.30]]; hint.numberOfLines = 2; hint.frame = CGRectMake(QFPMargin + 10, y, W - 20, 34); [_content addSubview:hint]; y += 42;

    self.contentHeight = y;
    _content.frame = CGRectMake(0, 0, W + QFPMargin * 2, y);
    _scroll.contentSize = CGSizeMake(W + QFPMargin * 2, y);
}

- (UILabel *)textLabel:(NSString *)text size:(CGFloat)size color:(UIColor *)color { UILabel *l = [[UILabel alloc] initWithFrame:CGRectZero]; l.text = text; l.font = [UIFont systemFontOfSize:size weight:UIFontWeightRegular]; l.textColor = color; return l; }
- (UILabel *)sectionLabel:(NSString *)text { UILabel *l = [self textLabel:text size:13 color:[QFPanelView muted]]; l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]; return l; }
- (UILabel *)valueLabel { UILabel *l = [self textLabel:@"" size:13 color:[QFPanelView cyan]]; l.textAlignment = NSTextAlignmentRight; return l; }
- (UIView *)boxWithFrame:(CGRect)frame { UIView *v = [[UIView alloc] initWithFrame:frame]; v.backgroundColor = UIColor.clearColor; return v; }
- (UISlider *)slider { UISlider *s = [[UISlider alloc] initWithFrame:CGRectZero]; s.minimumTrackTintColor = [QFPanelView cyan]; s.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.18]; return s; }
- (UIButton *)actionButton:(NSString *)title frame:(CGRect)frame { UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem]; b.frame = frame; b.backgroundColor = [QFPanelView rowBg]; b.layer.cornerRadius = 10; b.layer.masksToBounds = YES; [b setTitle:title forState:UIControlStateNormal]; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]; return b; }
- (void)layoutSwitch:(UISwitch *)sw inRow:(UIView *)row { CGSize s = [sw sizeThatFits:CGSizeZero]; sw.frame = CGRectMake(CGRectGetWidth(row.bounds) - s.width - 10, (CGRectGetHeight(row.bounds) - s.height) / 2.0, s.width, s.height); }

- (UISwitch *)miscSwitchRow:(NSString *)title key:(NSString *)key tag:(NSInteger)tag y:(CGFloat)y {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(QFPMargin, y, self.contentWidth, 46)];
    UILabel *l = [self textLabel:title size:15 color:UIColor.whiteColor]; l.frame = CGRectMake(0, 0, self.contentWidth - 72, 46); [row addSubview:l];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero]; sw.onTintColor = [QFPanelView cyan]; sw.tag = tag; sw.on = [key isEqualToString:@"freeDrag"] ? [QFPrefs shared].freeDrag : [QFPrefs shared].locked; [sw addTarget:self action:@selector(onMiscSwitch:) forControlEvents:UIControlEventValueChanged]; [row addSubview:sw]; [self layoutSwitch:sw inRow:row];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 45.5, self.contentWidth, 0.5)]; line.backgroundColor = [QFPanelView divider]; [row addSubview:line];
    [_content addSubview:row];
    return sw;
}

- (BOOL)boolForKey:(NSString *)key { QFPrefs *p = [QFPrefs shared]; if ([key isEqualToString:@"showCPU"]) return p.showCPU; if ([key isEqualToString:@"showFPS"]) return p.showFPS; if ([key isEqualToString:@"showUp"]) return p.showUp; if ([key isEqualToString:@"showDown"]) return p.showDown; return p.showBattery; }
- (void)setBool:(BOOL)value forKey:(NSString *)key { QFPrefs *p = [QFPrefs shared]; if ([key isEqualToString:@"showCPU"]) p.showCPU = value; else if ([key isEqualToString:@"showFPS"]) p.showFPS = value; else if ([key isEqualToString:@"showUp"]) p.showUp = value; else if ([key isEqualToString:@"showDown"]) p.showDown = value; else if ([key isEqualToString:@"showBattery"]) { p.showBattery = value; p.showCurrent = value; p.showPower = value; p.showTemp = value; } }

#pragma mark - 事件
- (void)onClose { if ([self.delegate respondsToSelector:@selector(panelDidClose:)]) [self.delegate panelDidClose:self]; }
- (void)notifyPrefs { [[QFPrefs shared] save]; [self refreshPreview]; if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) [self.delegate panelPrefsChanged:self]; }
- (void)onSwitch:(UISwitch *)sender { NSArray *keys = @[@"showCPU", @"showFPS", @"showUp", @"showDown", @"showBattery"]; if (sender.tag < 0 || sender.tag >= 5) return; [self setBool:sender.isOn forKey:keys[sender.tag]]; [self notifyPrefs]; }
- (void)onMiscSwitch:(UISwitch *)sender { if (sender.tag == 401) [QFPrefs shared].freeDrag = sender.isOn; if (sender.tag == 402) [QFPrefs shared].locked = sender.isOn; [self notifyPrefs]; }
- (void)onFontSlider { [QFPrefs shared].fontSize = round(self.fontSlider.value); [self notifyPrefs]; }
- (void)onScaleSlider { [QFPrefs shared].scale = round(self.scaleSlider.value * 100.0) / 100.0; [self notifyPrefs]; }
- (void)onResetPosition { [[QFPrefs shared] resetPosition]; if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) [self.delegate panelPrefsChanged:self]; }
- (void)onGrid:(UIButton *)sender { NSInteger i = sender.tag - 300; QFPrefs *p = [QFPrefs shared]; if (i == 4) [p resetPosition]; else { p.posX = (i % 3 == 0) ? 0.08 : (i % 3 == 2 ? 0.92 : 0.50); p.posY = (i / 3 == 0) ? 0.12 : (i / 3 == 2 ? 0.88 : 0.50); [p save]; } if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) [self.delegate panelPrefsChanged:self]; }
- (void)onNudge:(UIButton *)sender { QFPrefs *p = [QFPrefs shared]; CGFloat step = 0.025; switch (sender.tag - 320) { case 0: p.posX = MAX(0, p.posX - step); break; case 1: p.posY = MAX(0, p.posY - step); break; case 2: p.posY = MIN(1, p.posY + step); break; case 3: p.posX = MIN(1, p.posX + step); break; default: return; } [p save]; if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) [self.delegate panelPrefsChanged:self]; }
- (void)onEdgeHide { QFPrefs *p = [QFPrefs shared]; p.posX = p.posX < 0.5 ? 0.08 : 0.92; [p save]; if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) [self.delegate panelPrefsChanged:self]; }
- (void)onHideHUD { if ([self.delegate respondsToSelector:@selector(panelDidRequestExit:)]) [self.delegate panelDidRequestExit:self]; }

#pragma mark - 预览
- (void)refreshPreview {
    QFPrefs *p = [QFPrefs shared]; QFMetrics *m = [QFMetrics shared]; CGFloat fs = MAX(8.0, MIN(18.0, p.fontSize * p.scale)); UIFont *f = [UIFont monospacedDigitSystemFontOfSize:fs weight:UIFontWeightSemibold];
    NSMutableString *s = [NSMutableString string]; if (p.showCPU) [s appendFormat:@"CPU %.0f%%  ", m.cpuPercent]; if (p.showFPS) [s appendFormat:@"FPS %.0f  ", m.fps]; if (p.showUp) [s appendFormat:@"上传↑ %@  ", [QFMetrics formatRate:m.upBps]]; if (p.showDown) [s appendFormat:@"下载↓ %@  ", [QFMetrics formatRate:m.downBps]]; if (p.showBattery) [s appendFormat:@"电池 %d%%", m.batteryPercent];
    if (!_previewLabel) return; _previewLabel.font = f; _previewLabel.textColor = [QFPanelView cyan]; _previewLabel.text = s.length ? s : @"QFMonitor";
}

#pragma mark - 布局
- (void)layoutSubviews {
    [super layoutSubviews]; CGFloat W = CGRectGetWidth(self.bounds), H = CGRectGetHeight(self.bounds); if (W <= 0 || H <= 0) return; CGFloat inset = 0; if (@available(iOS 11.0, *)) inset = self.safeAreaInsets.top; if (inset <= 0) inset = 44; CGFloat cardH = MIN(H - inset, 660.0); cardH = MAX(cardH, 420.0); self.card.frame = CGRectMake(0, inset, W, cardH); self.handle.frame = CGRectMake((W - 42) / 2, 8, 42, 5); self.titleLabel.frame = CGRectMake(28, 38, W - 100, 28); self.subtitleLabel.frame = CGRectMake(28, 66, W - 100, 18); self.closeButton.frame = CGRectMake(W - 58, 30, 34, 34); self.scroll.frame = CGRectMake(0, 92, W, cardH - 92); if (self.contentWidth != W - 2 * QFPMargin) { self.contentWidth = W - 2 * QFPMargin; [self buildContent]; } self.content.frame = CGRectMake(0, 0, W, self.contentHeight); self.scroll.contentSize = CGSizeMake(W, self.contentHeight); [self syncLabels]; }
- (void)syncLabels { QFPrefs *p = [QFPrefs shared]; self.fontValueLabel.text = [NSString stringWithFormat:@"%.0fpt", p.fontSize]; self.scaleValueLabel.text = [NSString stringWithFormat:@"%.2fx", p.scale]; self.fontSlider.value = p.fontSize; self.scaleSlider.value = p.scale; }
- (void)presentInView:(UIView *)host animated:(BOOL)animated { self.frame = host.bounds; self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; [host addSubview:self]; [self refreshPreview]; [self syncLabels]; if (animated) { self.alpha = 0; self.card.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(self.card.bounds)); [UIView animateWithDuration:0.28 animations:^{ self.alpha = 1; self.card.transform = CGAffineTransformIdentity; }]; } }
- (void)dismissAnimated:(BOOL)animated { if (!animated) { [self removeFromSuperview]; return; } [UIView animateWithDuration:0.22 animations:^{ self.alpha = 0; self.card.transform = CGAffineTransformMakeTranslation(0, -CGRectGetHeight(self.card.bounds)); } completion:^(BOOL finished){ [self removeFromSuperview]; }]; }

@end
