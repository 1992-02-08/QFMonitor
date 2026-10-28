//
//  QFPanelView.m
//  底部抽屉设置面板。
//

#import "QFPanelView.h"
#import "QFPrefs.h"

@interface QFPanelView () <UIScrollViewDelegate>
@property (nonatomic, strong) UIVisualEffectView *sheet;      // 面板主体（毛玻璃+圆角）
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UILabel *previewLabel;          // 实时预览
@property (nonatomic, strong) UISlider *fontSlider;
@property (nonatomic, strong) UILabel *fontValue;
@property (nonatomic, strong) UISlider *scaleSlider;
@property (nonatomic, strong) UILabel *scaleValue;

@property (nonatomic, strong) NSMutableArray<UISwitch *> *switches;
@property (nonatomic, strong) NSArray<NSString *> *switchKeys;
@property (nonatomic, strong) NSMutableArray<UIButton *> *presetButtons;

@property (nonatomic, assign) BOOL visible;
@end

@interface QFPanelView (private)
- (CGRect)_rootBounds;
@end

@implementation QFPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        [self _build];
    }
    return self;
}

- (void)_build {
    // 半透明遮罩（点击空白收起）
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.alpha = 0;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
    [self addGestureRecognizer:tap];

    CGFloat w = self.bounds.size.width;
    // 76% 高
    CGFloat panelH = self.bounds.size.height * 0.76;

    _sheet = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _sheet.frame = CGRectMake(0, 0, w, panelH);
    _sheet.clipsToBounds = YES;
    // 仅顶部两角圆角
    UIBezierPath *mask = [UIBezierPath bezierPathWithRoundedRect:_sheet.bounds
                                               byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight)
                                                     cornerRadii:CGSizeMake(24, 24)];
    CAShapeLayer *shape = [CAShapeLayer layer];
    shape.path = mask.CGPath;
    _sheet.layer.mask = shape;
    _sheet.userInteractionEnabled = YES;
    [self addSubview:_sheet];

    // 面板内容自己接收触摸（不被遮罩 tap 拦截）
    UIView *contentHost = [UIView new];
    contentHost.frame = _sheet.bounds;
    contentHost.userInteractionEnabled = YES;
    contentHost.backgroundColor = [UIColor clearColor];
    [_sheet.contentView addSubview:contentHost];

    // 标题栏
    UILabel *title = [UILabel new];
    title.text = @"悬浮监控设置";
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    title.textColor = [UIColor whiteColor];
    title.frame = CGRectMake(20, 14, 180, 26);
    [contentHost addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    close.tintColor = [UIColor whiteColor];
    close.frame = CGRectMake(w - 48, 14, 32, 26);
    [close addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [contentHost addSubview:close];

    // 滚动区
    _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 52, w, panelH - 52)];
    _scroll.userInteractionEnabled = YES;
    _scroll.showsVerticalScrollIndicator = NO;
    [contentHost addSubview:_scroll];

    CGFloat y = 8;
    y = [self _addPreviewAt:y];
    y = [self _addFontSectionAt:y];
    y = [self _addScaleSectionAt:y];
    y = [self _addTogglesAt:y];
    y = [self _addActionsAt:y];

    _scroll.contentSize = CGSizeMake(w, y + 40);
}

#pragma mark - 实时预览
- (CGFloat)_addPreviewAt:(CGFloat)y {
    UILabel *lab = [UILabel new];
    lab.text = @"实时预览";
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lab.textColor = [UIColor systemGrayColor];
    CGFloat w = self.bounds.size.width;
    lab.frame = CGRectMake(20, y, 200, 20);
    [_scroll addSubview:lab];
    y += 24;

    _previewLabel = [UILabel new];
    _previewLabel.textColor = [UIColor whiteColor];
    _previewLabel.frame = CGRectMake(20, y, w - 40, 34);
    _previewLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
    _previewLabel.layer.cornerRadius = 8;
    _previewLabel.clipsToBounds = YES;
    _previewLabel.textAlignment = NSTextAlignmentCenter;
    [_scroll addSubview:_previewLabel];
    return y + 44;
}

#pragma mark - 字号
- (CGFloat)_addFontSectionAt:(CGFloat)y {
    CGFloat w = self.bounds.size.width;
    UILabel *lab = [UILabel new];
    lab.text = @"字号";
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lab.textColor = [UIColor systemGrayColor];
    lab.frame = CGRectMake(20, y, 120, 20);
    [_scroll addSubview:lab];

    _fontValue = [UILabel new];
    _fontValue.textColor = [UIColor whiteColor];
    _fontValue.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightMedium];
    _fontValue.textAlignment = NSTextAlignmentRight;
    _fontValue.frame = CGRectMake(w - 70, y, 50, 20);
    [_scroll addSubview:_fontValue];
    y += 26;

    _fontSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, y, w - 40, 30)];
    _fontSlider.minimumValue = 8; _fontSlider.maximumValue = 24; _fontSlider.continuous = YES;
    _fontSlider.value = [QFPrefs shared].fontSize;
    [_fontSlider addTarget:self action:@selector(_fontChanged:) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_fontSlider];
    y += 32;

    // 4 档预设
    NSArray<NSNumber*> *presets = @[@(9), @(11), @(14), @(18)];
    NSArray<NSString*> *names = @[@"小9", @"标准11", @"大14", @"特大18"];
    CGFloat pw = (w - 40 - 12*3) / 4.0;
    _presetButtons = [NSMutableArray array];
    for (int i = 0; i < 4; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.frame = CGRectMake(20 + i*(pw+12), y, pw, 30);
        [b setTitle:names[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        b.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
        b.layer.cornerRadius = 6;
        b.tintColor = [UIColor whiteColor];
        b.tag = i;
        [b addTarget:self action:@selector(_presetTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_scroll addSubview:b];
        [_presetButtons addObject:b];
    }
    [self _syncPresetAppearance];
    return y + 40;
}

#pragma mark - 整体缩放
- (CGFloat)_addScaleSectionAt:(CGFloat)y {
    CGFloat w = self.bounds.size.width;
    UILabel *lab = [UILabel new];
    lab.text = @"整体缩放";
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lab.textColor = [UIColor systemGrayColor];
    lab.frame = CGRectMake(20, y, 140, 20);
    [_scroll addSubview:lab];

    _scaleValue = [UILabel new];
    _scaleValue.textColor = [UIColor whiteColor];
    _scaleValue.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightMedium];
    _scaleValue.textAlignment = NSTextAlignmentRight;
    _scaleValue.frame = CGRectMake(w - 90, y, 70, 20);
    [_scroll addSubview:_scaleValue];
    y += 26;

    _scaleSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, y, w - 40, 30)];
    _scaleSlider.minimumValue = 0.6; _scaleSlider.maximumValue = 2.0; _scaleSlider.continuous = YES;
    _scaleSlider.value = [QFPrefs shared].scaleFactor;
    [_scaleSlider addTarget:self action:@selector(_scaleChanged:) forControlEvents:UIControlEventValueChanged];
    [_scroll addSubview:_scaleSlider];
    return y + 42;
}

#pragma mark - 显示开关
- (CGFloat)_addTogglesAt:(CGFloat)y {
    CGFloat w = self.bounds.size.width;
    UILabel *lab = [UILabel new];
    lab.text = @"显示项";
    lab.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lab.textColor = [UIColor systemGrayColor];
    lab.frame = CGRectMake(20, y, 120, 20);
    [_scroll addSubview:lab];
    y += 26;

    NSArray<NSString*> *titles = @[@"CPU", @"FPS", @"下行", @"上行", @"电量", @"温度", @"功率"];
    QFPrefs *p = [QFPrefs shared];
    _switches = [NSMutableArray array];
    for (int i = 0; i < titles.count; i++) {
        CGFloat rowY = y + i * 44;
        UIView *row = [UIView new];
        row.frame = CGRectMake(20, rowY, w - 40, 40);
        row.backgroundColor = [UIColor clearColor];
        row.userInteractionEnabled = YES;
        [_scroll addSubview:row];

        UILabel *t = [UILabel new];
        t.text = titles[i];
        t.font = [UIFont systemFontOfSize:15];
        t.textColor = [UIColor whiteColor];
        t.frame = CGRectMake(0, 8, 120, 24);
        [row addSubview:t];

        UISwitch *sw = [[UISwitch alloc] init];
        sw.transform = CGAffineTransformMakeScale(0.8, 0.8);
        sw.frame = CGRectMake(row.frame.size.width - 60, 2, 50, 30);
        BOOL val = [self _switchValueFor:i prefs:p];
        sw.on = val;
        sw.tag = 100 + i;
        [sw addTarget:self action:@selector(_toggleChanged:) forControlEvents:UIControlEventValueChanged];
        [row addSubview:sw];
        [_switches addObject:sw];
    }
    return y + titles.count * 44 + 8;
}

- (BOOL)_switchValueFor:(NSInteger)i prefs:(QFPrefs*)p {
    switch (i) {
        case 0: return p.showCPU;
        case 1: return p.showFPS;
        case 2: return p.showDown;
        case 3: return p.showUp;
        case 4: return p.showBattery;
        case 5: return p.showTemp;
        case 6: return p.showPower;
    }
    return NO;
}

#pragma mark - 动作
- (CGFloat)_addActionsAt:(CGFloat)y {
    CGFloat w = self.bounds.size.width;
    CGFloat bw = (w - 40 - 12) / 2.0;

    UIButton *reset = [self _actionButton:@"回到顶部" color:[UIColor systemBlueColor] frame:CGRectMake(20, y, bw, 44)];
    [reset addTarget:self action:@selector(_resetPos) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:reset];

    UIButton *pt = [self _actionButton:@"触摸穿透" color:[UIColor systemIndigoColor] frame:CGRectMake(20 + bw + 12, y, bw, 44)];
    [pt addTarget:self action:@selector(_togglePassthrough) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:pt];
    _passthroughButton = pt;
    [self _syncPassthroughLabel];
    y += 56;

    UIButton *endFloat = [self _actionButton:@"结束悬浮窗" color:[UIColor systemOrangeColor] frame:CGRectMake(20, y, bw, 44)];
    [endFloat addTarget:self action:@selector(_endFloat) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:endFloat];

    UIButton *exit = [self _actionButton:@"退出 App" color:[UIColor systemRedColor] frame:CGRectMake(20 + bw + 12, y, bw, 44)];
    [exit addTarget:self action:@selector(_exitApp) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:exit];
    return y + 56;
}

- (UIButton *)_actionButton:(NSString*)title color:(UIColor*)color frame:(CGRect)frame {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = frame;
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    b.backgroundColor = color;
    b.tintColor = [UIColor whiteColor];
    b.layer.cornerRadius = 10;
    b.clipsToBounds = YES;
    return b;
}

#pragma mark - 事件

- (void)_fontChanged:(UISlider*)s {
    [QFPrefs shared].fontSize = s.value;
    _fontValue.text = [NSString stringWithFormat:@"%.0f pt", s.value];
    [self _applyAndSave];
    [self _syncPresetAppearance];
}
- (void)_presetTapped:(UIButton*)b {
    CGFloat v = [QFPrefs presetSize:b.tag];
    [QFPrefs shared].fontSize = v;
    _fontSlider.value = v;
    _fontValue.text = [NSString stringWithFormat:@"%.0f pt", v];
    [self _applyAndSave];
    [self _syncPresetAppearance];
}
- (void)_scaleChanged:(UISlider*)s {
    [QFPrefs shared].scaleFactor = s.value;
    _scaleValue.text = [NSString stringWithFormat:@"%.2f ×", s.value];
    [self _applyAndSave];
}
- (void)_toggleChanged:(UISwitch*)sw {
    NSInteger i = sw.tag - 100;
    QFPrefs *p = [QFPrefs shared];
    switch (i) {
        case 0: p.showCPU = sw.on; break;
        case 1: p.showFPS = sw.on; break;
        case 2: p.showDown = sw.on; break;
        case 3: p.showUp = sw.on; break;
        case 4: p.showBattery = sw.on; break;
        case 5: p.showTemp = sw.on; break;
        case 6: p.showPower = sw.on; break;
    }
    [self _applyAndSave];
}
- (void)_resetPos {
    [QFPrefs shared].normalizedPosition = CGPointMake(0.5, 0.3);
    [self _applyAndSave];
    [self _notifyResetPos];
}
- (void)_togglePassthrough {
    QFPrefs *p = [QFPrefs shared];
    p.passthrough = !p.passthrough;
    [self _applyAndSave];
    [self _syncPassthroughLabel];
}
- (void)_endFloat { [self _notifyEndFloat]; }
- (void)_exitApp { [self _notifyExitApp]; }

- (void)_applyAndSave {
    [[QFPrefs shared] save];
    [self _updatePreview];
}

#pragma mark - 回调（由控制器实现）
- (void)_notifyResetPos   { if (self.onResetPosition) self.onResetPosition(); }
- (void)_notifyEndFloat   { if (self.onEndFloat) self.onEndFloat(); }
- (void)_notifyExitApp    { if (self.onExitApp) self.onExitApp(); }

#pragma mark - 预览与外观同步

- (void)_updatePreview {
    QFPrefs *p = [QFPrefs shared];
    // 预览内容示例（用虚拟值构一句）
    NSMutableString *s = [NSMutableString string];
    if (p.showCPU)   [s appendString:@"CPU 12% "];
    if (p.showFPS)   [s appendString:@"60 "];
    if (p.showDown)  [s appendString:@"↓128K "];
    if (p.showUp)    [s appendString:@"↑32K "];
    if (p.showBattery)[s appendString:@"72% "];
    if (p.showTemp)  [s appendString:@"31° "];
    if (p.showPower) [s appendString:@"+2.1W "];
    if (s.length == 0) [s appendString:@"（已全关）"];
    _previewLabel.text = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    _previewLabel.font = [UIFont systemFontOfSize:p.fontSize * p.scaleFactor];
}

- (void)_syncPresetAppearance {
    QFPrefs *p = [QFPrefs shared];
    for (UIButton *b in _presetButtons) {
        BOOL active = fabs([QFPrefs presetSize:b.tag] - p.fontSize) < 0.01;
        b.backgroundColor = active ? [UIColor colorWithRed:0.2 green:0.5 blue:1 alpha:0.9]
                                   : [UIColor colorWithWhite:1 alpha:0.12];
    }
}

- (void)_syncPassthroughLabel {
    BOOL on = [QFPrefs shared].passthrough;
    _passthroughButton.backgroundColor = on ? [UIColor systemGreenColor] : [UIColor systemIndigoColor];
}

#pragma mark - 展示/收起

- (void)refresh { [self _updatePreview]; [self _syncPresetAppearance]; [self _syncPassthroughLabel]; }

- (void)present {
    if (_visible) return;
    _visible = YES;
    self.frame = [self _rootBounds];
    [self layoutIfNeeded];
    for (UIView *v in self.subviews) v.userInteractionEnabled = YES;
    self.alpha = 1;
    // 更新 sheet 位置（默认在底部）
    _sheet.frame = CGRectMake(0, [self _rootBounds].size.height - _sheet.frame.size.height,
                              _sheet.frame.size.width, _sheet.frame.size.height);
    [self refresh];
    // 弹簧动画
    self.alpha = 0;
    CATransform3D t = CATransform3DIdentity;
    t = CATransform3DTranslate(t, 0, _sheet.frame.size.height, 0);
    _sheet.layer.transform = t;
    [UIView animateWithDuration:0.32 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1;
        self->_sheet.layer.transform = CATransform3DIdentity;
    } completion:nil];
}

- (void)dismiss {
    if (!_visible) return;
    _visible = NO;
    [UIView animateWithDuration:0.22 animations:^{
        self.alpha = 0;
        CATransform3D t = CATransform3DIdentity;
        t = CATransform3DTranslate(t, 0, self.sheet.frame.size.height, 0);
        self->_sheet.layer.transform = t;
    } completion:^(BOOL f){ [self removeFromSuperview]; }];
}

- (CGRect)_rootBounds {
    return [UIScreen mainScreen].bounds;
}

@end