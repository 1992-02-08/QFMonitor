//
//  QFPanelView.m
//

#import "QFPanelView.h"
#import "QFPrefs.h"
#import "QFMetrics.h"

#define QFPMargin   16.0
#define QFPCardR    16.0

@interface QFPanelView ()
@property (nonatomic, strong) UIView        *card;
@property (nonatomic, strong) UIScrollView  *scroll;
@property (nonatomic, strong) UIView        *content;
@property (nonatomic, strong) UILabel       *previewLabel;
@property (nonatomic, strong) UILabel       *fontValueLabel;
@property (nonatomic, strong) UILabel       *scaleValueLabel;
@property (nonatomic, strong) UISlider      *fontSlider;
@property (nonatomic, strong) UISlider      *scaleSlider;
@property (nonatomic, strong) NSMutableArray *presetButtons;
@property (nonatomic, strong) NSMutableArray *presetSizes;
@property (nonatomic, strong) NSMutableArray *switches;
@property (nonatomic, strong) NSMutableArray *accentButtons;
@property (nonatomic, strong) UISwitch      *passthroughSwitch;
@property (nonatomic, strong) UIView        *handle;
@property (nonatomic, strong) UILabel       *titleLabel;
@property (nonatomic, strong) UILabel       *subtitleLabel;
@property (nonatomic, strong) UIButton      *closeButton;
@property (nonatomic, assign) CGFloat        contentHeight;
@property (nonatomic, assign) CGFloat        contentWidth;
@end

@implementation QFPanelView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.presetButtons = [NSMutableArray array];
        self.presetSizes  = [NSMutableArray array];
        self.switches     = [NSMutableArray array];
        self.accentButtons= [NSMutableArray array];
        [self buildUI];
    }
    return self;
}

#pragma mark - 配色工具

+ (NSArray<UIColor *> *)accentPalette {
    return @[
        [UIColor colorWithRed:0.36 green:0.86 blue:1.00 alpha:1.0],
        [UIColor colorWithRed:0.40 green:0.90 blue:0.60 alpha:1.0],
        [UIColor colorWithRed:1.00 green:0.70 blue:0.32 alpha:1.0],
        [UIColor colorWithRed:0.72 green:0.60 blue:1.00 alpha:1.0],
        [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0],
        [UIColor colorWithRed:1.00 green:0.52 blue:0.74 alpha:1.0],
    ];
}

+ (UIColor *)cardBg {
    return [UIColor colorWithRed:0.10 green:0.11 blue:0.14 alpha:0.96];
}

+ (UIColor *)subBg {
    return [UIColor colorWithWhite:1.0 alpha:0.07];
}

+ (UIColor *)dimText {
    return [UIColor colorWithWhite:1.0 alpha:0.55];
}

#pragma mark - UI 构建

- (void)buildUI {
    CGFloat W = CGRectGetWidth(self.bounds) > 0 ? CGRectGetWidth(self.bounds) : 390.0;
    _contentWidth = W - 2 * QFPMargin;

    // 卡片
    _card = [[UIView alloc] initWithFrame:CGRectZero];
    _card.backgroundColor = [[self class] cardBg];
    _card.layer.cornerRadius = QFPCardR;
    _card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    _card.layer.masksToBounds = YES;
    [self addSubview:_card];

    // 顶部抓手
    UIView *handle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 5)];
    handle.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.32];
    handle.layer.cornerRadius = 2.5;
    [_card addSubview:handle];
    self.handle = handle;

    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.text = @"QFMonitor 设置";
    title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    title.textColor = [UIColor whiteColor];
    [_card addSubview:title];
    self.titleLabel = title;

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectZero];
    sub.text = @"单行悬浮网速 · 自绘面板";
    sub.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightRegular];
    sub.textColor = [[self class] dimText];
    [_card addSubview:sub];
    self.subtitleLabel = sub;

    // 关闭
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"完成" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [close setTitleColor:[[self class] accentPalette][0] forState:UIControlStateNormal];
    [close addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [_card addSubview:close];
    self.closeButton = close;

    // 滚动区
    _scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scroll.showsVerticalScrollIndicator = NO;
    _scroll.alwaysBounceVertical = YES;
    _scroll.backgroundColor = [UIColor clearColor];
    [_card addSubview:_scroll];

    _content = [[UIView alloc] initWithFrame:CGRectZero];
    _content.backgroundColor = [UIColor clearColor];
    [_scroll addSubview:_content];

    [self buildContent];
}

- (void)buildContent {
    [_content.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.presetButtons removeAllObjects];
    [self.switches removeAllObjects];
    [self.accentButtons removeAllObjects];

    CGFloat y = 0;
    CGFloat W = _contentWidth;

    // ---------- 预览 ----------
    y += 6;
    UIView *previewCard = [self cardWithHeight:66];
    previewCard.frame = CGRectMake(QFPMargin, y, W, 66);
    [_content addSubview:previewCard];
    UILabel *cap = [self captionInCard:previewCard text:@"实时预览" atY:8];
    (void)cap;
    _previewLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 30, W - 24, 26)];
    _previewLabel.numberOfLines = 1;
    _previewLabel.textAlignment = NSTextAlignmentCenter;
    [previewCard addSubview:_previewLabel];
    y += 66 + 14;

    // ---------- 字号 ----------
    UIView *fontCard = [self cardWithHeight:132];
    fontCard.frame = CGRectMake(QFPMargin, y, W, 132);
    [_content addSubview:fontCard];
    [self captionInCard:fontCard text:@"字号" atY:8];
    _fontValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _fontValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold];
    _fontValueLabel.textColor = [[self class] accentPalette][0];
    _fontValueLabel.textAlignment = NSTextAlignmentRight;
    [fontCard addSubview:_fontValueLabel];

    _fontSlider = [[UISlider alloc] initWithFrame:CGRectMake(12, 30, W - 24, 30)];
    _fontSlider.minimumValue = 8.0;
    _fontSlider.maximumValue = 24.0;
    _fontSlider.minimumTrackTintColor = [[self class] accentPalette][0];
    [_fontSlider addTarget:self action:@selector(onFontSlider) forControlEvents:UIControlEventValueChanged];
    [fontCard addSubview:_fontSlider];

    NSArray *presetTitles = @[@"小", @"标准", @"大", @"特大"];
    NSArray *presetSizes  = @[@9.0, @11.0, @14.0, @18.0];
    if (!self.presetSizes) self.presetSizes = [NSMutableArray array];
    [self.presetButtons removeAllObjects];
    [self.switches removeAllObjects];
    [self.accentButtons removeAllObjects];
    CGFloat bw = (W - 24 - 18) / 4.0;
    for (int i = 0; i < 4; i++) {
        UIButton *b = [self pillButton:presetTitles[i]
                                  frame:CGRectMake(12 + i * (bw + 6), 74, bw, 34)];
        b.tag = 100 + i;
        [b addTarget:self action:@selector(onPreset:) forControlEvents:UIControlEventTouchUpInside];
        [fontCard addSubview:b];
        [self.presetButtons addObject:b];
        [self.presetSizes addObject:presetSizes[i]];
    }
    y += 132 + 14;

    // ---------- 整体缩放 ----------
    UIView *scaleCard = [self cardWithHeight:76];
    scaleCard.frame = CGRectMake(QFPMargin, y, W, 76);
    [_content addSubview:scaleCard];
    [self captionInCard:scaleCard text:@"整体缩放" atY:8];
    _scaleValueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _scaleValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold];
    _scaleValueLabel.textColor = [[self class] accentPalette][0];
    _scaleValueLabel.textAlignment = NSTextAlignmentRight;
    [scaleCard addSubview:_scaleValueLabel];
    _scaleSlider = [[UISlider alloc] initWithFrame:CGRectMake(12, 34, W - 24, 30)];
    _scaleSlider.minimumValue = 0.6;
    _scaleSlider.maximumValue = 2.0;
    _scaleSlider.minimumTrackTintColor = [[self class] accentPalette][0];
    [_scaleSlider addTarget:self action:@selector(onScaleSlider) forControlEvents:UIControlEventValueChanged];
    [scaleCard addSubview:_scaleSlider];
    y += 76 + 14;

    // ---------- 显示项目 ----------
    NSArray *names = @[@"CPU 占用", @"帧率 FPS", @"上传速度 ↑", @"下载速度 ↓",
                        @"电量 BAT", @"电流 mA", @"瓦数 W", @"温度 °C"];
    NSArray *keys  = @[@"showCPU", @"showFPS", @"showUp", @"showDown",
                        @"showBattery", @"showCurrent", @"showPower", @"showTemp"];
    CGFloat rowH = 38;
    UIView *showCard = [self cardWithHeight:8 + rowH * 8 + 8];
    showCard.frame = CGRectMake(QFPMargin, y, W, 8 + rowH * 8 + 8);
    [_content addSubview:showCard];
    [self captionInCard:showCard text:@"显示项目" atY:8];
    for (int i = 0; i < 8; i++) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(12, 34 + i * rowH, W - 24, rowH)];
        row.backgroundColor = [UIColor clearColor];
        [showCard addSubview:row];

        UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, W - 24 - 60, rowH)];
        l.text = names[i];
        l.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        l.textColor = [UIColor whiteColor];
        [row addSubview:l];

        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
        sw.onTintColor = [[self class] accentPalette][0];
        [sw setOn:[self boolForKey:keys[i]]];
        [sw addTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
        sw.tag = i;
        [row addSubview:sw];
        [self layoutSwitch:sw inRow:row];
        [self.switches addObject:sw];

        if (i < 6) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, rowH - 0.5, W - 24, 0.5)];
            line.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
            [row addSubview:line];
        }
    }
    y += showCard.frame.size.height + 14;

    // ---------- 配色 ----------
    UIView *colorCard = [self cardWithHeight:74];
    colorCard.frame = CGRectMake(QFPMargin, y, W, 74);
    [_content addSubview:colorCard];
    [self captionInCard:colorCard text:@"配色" atY:8];
    CGFloat cbs = 30;
    CGFloat gapc = (W - 24 - cbs * 6) / 5.0;
    for (int i = 0; i < 6; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(12 + i * (cbs + gapc), 36, cbs, cbs);
        b.backgroundColor = [[self class] accentPalette][i];
        b.layer.cornerRadius = cbs / 2.0;
        b.layer.borderWidth = 2.0;
        b.layer.borderColor = [UIColor clearColor].CGColor;
        b.tag = 200 + i;
        [b addTarget:self action:@selector(onAccent:) forControlEvents:UIControlEventTouchUpInside];
        [colorCard addSubview:b];
        [self.accentButtons addObject:b];
    }
    y += 74 + 14;

    // ---------- 位置 ----------
    // 九宫格 + 微调 + 自由移动 + 锁定
    UIView *posCard = [self cardWithHeight:236];
    posCard.frame = CGRectMake(QFPMargin, y, W, 236);
    [_content addSubview:posCard];
    [self captionInCard:posCard text:@"位置调节" atY:8];

    // 九宫格
    NSArray *gridTitles = @[@"↖", @"↑", @"↗", @"←", @"中心", @"→", @"↙", @"↓", @"↘"];
    CGFloat gw = (W - 24 - 12) / 3.0;
    CGFloat gh = 26;
    for (int i = 0; i < 9; i++) {
        int gx = i % 3, gy = i / 3;
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.frame = CGRectMake(12 + gx * (gw + 6), 30 + gy * (gh + 6), gw, gh);
        [b setTitle:gridTitles[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
        b.layer.cornerRadius = 6;
        b.tag = 300 + i;
        [b addTarget:self action:@selector(onGrid:) forControlEvents:UIControlEventTouchUpInside];
        [posCard addSubview:b];
    }
    // 微调
    NSArray *nudgeTitles = @[@"◀ 微调左", @"▲ 上移", @"▼ 下移", @"▶ 微调右"];
    CGFloat nw = (W - 24 - 18) / 4.0;
    for (int i = 0; i < 4; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.frame = CGRectMake(12 + i * (nw + 6), 30 + 3 * (gh + 6) + 6, nw, gh);
        [b setTitle:nudgeTitles[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
        b.layer.cornerRadius = 6;
        b.tag = 320 + i;
        [b addTarget:self action:@selector(onNudge:) forControlEvents:UIControlEventTouchUpInside];
        [posCard addSubview:b];
    }
    // 自由移动 + 锁定位置
    CGFloat yy = 30 + 4 * (gh + 6) + 10;
    [self addSwitchRowIn:posCard title:@"自由移动（拖动）" key:@"freeDrag" tag:401 atY:yy];
    [self addSwitchRowIn:posCard title:@"🔒 锁定位置（防误拖）" key:@"locked" tag:402 atY:yy + 36];
    // 重置位置
    UIButton *reset = [self pillButton:@"重置位置"
                                frame:CGRectMake(12, yy + 72, W - 24, 30)];
    reset.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [reset addTarget:self action:@selector(onResetPosition) forControlEvents:UIControlEventTouchUpInside];
    [posCard addSubview:reset];
    y += 236 + 14;

    // ---------- 操作 ----------
    UIView *actCard = [self cardWithHeight:134];
    actCard.frame = CGRectMake(QFPMargin, y, W, 134);
    [_content addSubview:actCard];
    [self captionInCard:actCard text:@"操作" atY:8];

    UIButton *exitBtn = [self pillButton:@"结束悬浮窗"
                                   frame:CGRectMake(12, 28, W - 24, 30)];
    exitBtn.titleLabel.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightSemibold];
    [exitBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.42 blue:0.42 alpha:1.0]
                  forState:UIControlStateNormal];
    [exitBtn addTarget:self action:@selector(onExit) forControlEvents:UIControlEventTouchUpInside];
    [actCard addSubview:exitBtn];

    // 触摸穿透开关
    UIView *ptRow = [[UIView alloc] initWithFrame:CGRectMake(12, 64, W - 24, 38)];
    [actCard addSubview:ptRow];
    UILabel *ptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, W - 24 - 60, 38)];
    ptLabel.text = @"触摸穿透";
    ptLabel.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightRegular];
    ptLabel.textColor = [UIColor whiteColor];
    [ptRow addSubview:ptLabel];
    UISwitch *ptSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    ptSwitch.onTintColor = [[self class] accentPalette][0];
    ptSwitch.on = [QFPrefs shared].passthrough;
    [ptSwitch addTarget:self action:@selector(onPassthrough:) forControlEvents:UIControlEventValueChanged];
    [ptRow addSubview:ptSwitch];
    [self layoutSwitch:ptSwitch inRow:ptRow];
    _passthroughSwitch = ptSwitch;

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(12, 104, W - 24, 26)];
    hint.text = @"拖动悬浮条可自由移动；点齿轮打开本面板";
    hint.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    hint.textColor = [[self class] dimText];
    hint.numberOfLines = 2;
    [actCard addSubview:hint];
    y += 134 + 20;

    _contentHeight = y;
    _content.frame = CGRectMake(0, 0, W, y);
    _scroll.contentSize = CGSizeMake(W, y);
}

#pragma mark - 小组件

- (UIView *)cardWithHeight:(CGFloat)h {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentWidth, h)];
    v.backgroundColor = [[self class] subBg];
    v.layer.cornerRadius = 13;
    v.layer.masksToBounds = YES;
    return v;
}

- (UILabel *)captionInCard:(UIView *)card text:(NSString *)t atY:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(12, y, _contentWidth - 24, 16)];
    l.text = t;
    l.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
    l.textColor = [[self class] dimText];
    [card addSubview:l];
    return l;
}

- (UIButton *)pillButton:(NSString *)t frame:(CGRect)f {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = f;
    [b setTitle:t forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    b.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    b.layer.cornerRadius = 9;
    b.layer.masksToBounds = YES;
    return b;
}

- (void)layoutSwitch:(UISwitch *)sw inRow:(UIView *)row {
    CGSize s = [sw sizeThatFits:CGSizeZero];
    sw.frame = CGRectMake(CGRectGetWidth(row.bounds) - s.width,
                          (CGRectGetHeight(row.bounds) - s.height) / 2.0,
                          s.width, s.height);
}

// 开关行(自由移动/锁定等)
- (void)addSwitchRowIn:(UIView *)card title:(NSString *)title key:(NSString *)key tag:(NSInteger)tag atY:(CGFloat)yy {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(12, yy, _contentWidth - 24, 34)];
    row.backgroundColor = [UIColor clearColor];
    [card addSubview:row];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _contentWidth - 24 - 60, 34)];
    l.text = title;
    l.font = [UIFont systemFontOfSize:13.5 weight:UIFontWeightRegular];
    l.textColor = [UIColor whiteColor];
    [row addSubview:l];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.onTintColor = [[self class] accentPalette][0];
    sw.tag = tag;
    if ([key isEqualToString:@"freeDrag"]) sw.on = [QFPrefs shared].freeDrag;
    else if ([key isEqualToString:@"locked"]) sw.on = [QFPrefs shared].locked;
    [sw addTarget:self action:@selector(onMiscSwitch:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    [self layoutSwitch:sw inRow:row];
}

- (void)onMiscSwitch:(UISwitch *)sender {
    QFPrefs *p = [QFPrefs shared];
    if (sender.tag == 401) p.freeDrag = sender.isOn;
    else if (sender.tag == 402) p.locked = sender.isOn;
    [p save];
    [self refreshPreview];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onGrid:(UIButton *)sender {
    NSInteger i = sender.tag - 300;
    if (i < 0 || i > 8) return;
    QFPrefs *p = [QFPrefs shared];
    if (i == 4) {
        [p resetPosition];
    } else {
        int gx = i % 3, gy = i / 3;
        p.posX = (gx == 0) ? 0.02 : (gx == 2 ? 0.98 : 0.5);
        p.posY = (gy == 0) ? 0.02 : (gy == 2 ? 0.98 : 0.5);
        [p save];
    }
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onNudge:(UIButton *)sender {
    NSInteger i = sender.tag - 320;
    if (i < 0 || i > 3) return;
    QFPrefs *p = [QFPrefs shared];
    CGFloat step = 0.03;
    if (i == 0) p.posX = MAX(0.0, p.posX - step);
    else if (i == 1) p.posY = MAX(0.0, p.posY - step);
    else if (i == 2) p.posY = MIN(1.0, p.posY + step);
    else if (i == 3) p.posX = MIN(1.0, p.posX + step);
    [p save];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (BOOL)boolForKey:(NSString *)k {
    QFPrefs *p = [QFPrefs shared];
    if ([k isEqualToString:@"showDown"])    return p.showDown;
    if ([k isEqualToString:@"showUp"])      return p.showUp;
    if ([k isEqualToString:@"showBattery"]) return p.showBattery;
    if ([k isEqualToString:@"showTemp"])    return p.showTemp;
    if ([k isEqualToString:@"showPower"])   return p.showPower;
    if ([k isEqualToString:@"showCPU"])     return p.showCPU;
    if ([k isEqualToString:@"showFPS"])     return p.showFPS;
    if ([k isEqualToString:@"showCurrent"]) return p.showCurrent;
    return YES;
}

- (void)setBool:(BOOL)v forKey:(NSString *)k {
    QFPrefs *p = [QFPrefs shared];
    if ([k isEqualToString:@"showDown"])    p.showDown = v;
    if ([k isEqualToString:@"showUp"])      p.showUp = v;
    if ([k isEqualToString:@"showBattery"]) p.showBattery = v;
    if ([k isEqualToString:@"showTemp"])    p.showTemp = v;
    if ([k isEqualToString:@"showPower"])   p.showPower = v;
    if ([k isEqualToString:@"showCPU"])     p.showCPU = v;
    if ([k isEqualToString:@"showFPS"])     p.showFPS = v;
    if ([k isEqualToString:@"showCurrent"]) p.showCurrent = v;
}

#pragma mark - 事件

- (void)onClose {
    if ([self.delegate respondsToSelector:@selector(panelDidClose:)]) {
        [self.delegate panelDidClose:self];
    }
}

- (void)onExit {
    if ([self.delegate respondsToSelector:@selector(panelDidRequestExit:)]) {
        [self.delegate panelDidRequestExit:self];
    }
}

- (void)onFontSlider {
    QFPrefs *p = [QFPrefs shared];
    p.fontSize = round(_fontSlider.value);
    _fontSlider.value = p.fontSize;
    [self syncLabels];
    [p save];
    [self refreshPreview];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onScaleSlider {
    QFPrefs *p = [QFPrefs shared];
    p.scale = round(_scaleSlider.value * 100.0) / 100.0;
    _scaleSlider.value = p.scale;
    [self syncLabels];
    [p save];
    [self refreshPreview];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onPreset:(UIButton *)sender {
    static const double sizes[4] = { 9.0, 11.0, 14.0, 18.0 };
    NSInteger idx = sender.tag - 100;
    if (idx < 0 || idx > 3) return;
    QFPrefs *p = [QFPrefs shared];
    p.fontSize = sizes[idx];
    _fontSlider.value = p.fontSize;
    [self syncLabels];
    [p save];
    [self refreshPreview];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onSwitch:(UISwitch *)sender {
    NSInteger i = sender.tag;
    if (i < 0 || i > 7) return;
    static NSArray *keys = @[@"showCPU", @"showFPS", @"showUp", @"showDown",
                             @"showBattery", @"showCurrent", @"showPower", @"showTemp"];
    [self setBool:sender.isOn forKey:keys[i]];
    [[QFPrefs shared] save];
    [self refreshPreview];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onAccent:(UIButton *)sender {
    NSInteger i = sender.tag - 200;
    if (i < 0 || i > 5) return;
    QFPrefs *p = [QFPrefs shared];
    p.accent = i;
    [p save];
    [self syncLabels];
    [self refreshPreview];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onResetPosition {
    [[QFPrefs shared] resetPosition];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)onPassthrough:(UISwitch *)sender {
    QFPrefs *p = [QFPrefs shared];
    p.passthrough = sender.isOn;
    [p save];
    if ([self.delegate respondsToSelector:@selector(panelPrefsChanged:)]) {
        [self.delegate panelPrefsChanged:self];
    }
}

- (void)syncLabels {
    QFPrefs *p = [QFPrefs shared];
    _fontValueLabel.text = [NSString stringWithFormat:@"%.0f pt", p.fontSize];
    _scaleValueLabel.text = [NSString stringWithFormat:@"%.2f×", p.scale];
    _fontSlider.value = p.fontSize;
    _scaleSlider.value = p.scale;

    for (int i = 0; i < 6; i++) {
        BOOL on = (i == p.accent);
        if (i < (NSInteger)self.accentButtons.count) {
            UIButton *ab = [self.accentButtons objectAtIndex:i];
            ab.layer.borderColor = on ? [UIColor whiteColor].CGColor : [UIColor clearColor].CGColor;
        }
    }
}

#pragma mark - 预览

- (void)refreshPreview {
    QFPrefs *p = [QFPrefs shared];
    QFMetrics *m = [QFMetrics shared];
    UIColor *accent = [[self class] accentPalette][MIN(MAX(p.accent, 0), 5)];

    CGFloat fs = MAX(9.0, MIN(20.0, p.fontSize * p.scale));
    UIFont *nf = [UIFont monospacedDigitSystemFontOfSize:fs weight:UIFontWeightSemibold];
    UIFont *lf = [UIFont monospacedDigitSystemFontOfSize:MAX(7.0, fs - 1.5) weight:UIFontWeightMedium];

    NSMutableAttributedString *out = [[NSMutableAttributedString alloc] init];
    NSMutableArray *segs = [NSMutableArray array];
    NSMutableArray *grp  = [NSMutableArray array];

    if (p.showDown) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"↓ " font:nf color:accent]];
        [a appendAttributedString:[self att:[QFMetrics formatRate:m.downBps] font:nf color:[UIColor whiteColor]]];
        [segs addObject:a]; [grp addObject:@0];
    }
    if (p.showUp) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"↑ " font:nf color:accent]];
        [a appendAttributedString:[self att:[QFMetrics formatRate:m.upBps] font:nf color:[UIColor whiteColor]]];
        [segs addObject:a]; [grp addObject:@0];
    }
    if (p.showBattery) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"⚡%d%%", m.batteryPercent]
                                       font:nf color:accent]];
        [segs addObject:a]; [grp addObject:@0];
    }
    if (p.showTemp) {
        NSString *t = (m.temperatureC > -100.0)
            ? [NSString stringWithFormat:@"%.0f°", m.temperatureC] : @"--°";
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:t font:nf color:[UIColor whiteColor]]];
        [segs addObject:a]; [grp addObject:@1];
    }
    if (p.showPower) {
        NSString *w = m.wattValid ? [NSString stringWithFormat:@"%+.2fW", m.watt] : @"--W";
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:w font:nf color:[UIColor whiteColor]]];
        [segs addObject:a]; [grp addObject:@1];
    }
    if (p.showCPU) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"CPU " font:lf color:[[self class] dimText]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%.0f%%", m.cpuPercent]
                                       font:nf color:[UIColor whiteColor]]];
        [segs addObject:a]; [grp addObject:@2];
    }
    if (p.showFPS) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:[self att:@"FPS " font:lf color:[[self class] dimText]]];
        [a appendAttributedString:[self att:[NSString stringWithFormat:@"%.0f", m.fps]
                                       font:nf color:[UIColor whiteColor]]];
        [segs addObject:a]; [grp addObject:@2];
    }

    for (NSInteger i = 0; i < (NSInteger)segs.count; i++) {
        if (i > 0) {
            BOOL newGrp = ([grp[i] intValue] != [grp[i - 1] intValue]);
            [out appendAttributedString:[self att:(newGrp ? @"   " : @"  ") font:nf color:[UIColor whiteColor]]];
        }
        [out appendAttributedString:segs[i]];
    }
    _previewLabel.attributedText = out;
}

- (NSAttributedString *)att:(NSString *)t font:(UIFont *)f color:(UIColor *)c {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (f) d[NSFontAttributeName] = f;
    d[NSForegroundColorAttributeName] = c ?: [UIColor whiteColor];
    return [[NSAttributedString alloc] initWithString:(t ?: @"") attributes:d];
}

#pragma mark - 布局 / 显隐

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat W = CGRectGetWidth(self.bounds);
    CGFloat H = CGRectGetHeight(self.bounds);
    if (W <= 0 || H <= 0) return;

    // 底部抽屉: 高度不超过屏高的 76%, 也不低于 300
    CGFloat cardH = MIN(620.0, MAX(300.0, H * 0.76));
    self.card.frame = CGRectMake(0, H - cardH, W, cardH);
    self.handle.frame = CGRectMake((W - 38) / 2.0, 8, 38, 5);
    self.titleLabel.frame = CGRectMake(QFPMargin, 20, W - QFPMargin * 2 - 60, 22);
    self.subtitleLabel.frame = CGRectMake(QFPMargin, 42, W - QFPMargin * 2 - 60, 14);
    self.closeButton.frame = CGRectMake(W - QFPMargin - 50, 18, 50, 26);

    CGFloat top = 64;
    self.scroll.frame = CGRectMake(0, top, W, cardH - top);

    if (_contentWidth != W - 2 * QFPMargin) {
        _contentWidth = W - 2 * QFPMargin;
        // 宽度变化时重建内容(少见, 只在极端尺寸下触发)
        [_content.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self buildContent];
    }
    self.content.frame = CGRectMake(0, 0, _contentWidth, _contentHeight);
    self.scroll.contentSize = CGSizeMake(_contentWidth, _contentHeight);

    self.fontValueLabel.frame = CGRectMake(_contentWidth - 92, 8, 80, 16);
    self.scaleValueLabel.frame = CGRectMake(_contentWidth - 92, 8, 80, 16);
}

- (void)presentInView:(UIView *)host animated:(BOOL)animated {
    self.frame = host.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [host addSubview:self];
    [self refreshPreview];
    [self syncLabels];

    if (animated) {
        self.alpha = 0;
        CGFloat H = CGRectGetHeight(self.card.bounds);
        self.card.transform = CGAffineTransformMakeTranslation(0, H);
        [UIView animateWithDuration:0.28
                              delay:0
                            usingSpringWithDamping:0.92
                             initialSpringVelocity:0.4
                           options:UIViewAnimationOptionCurveEaseOut
                           animations:^{
            self.alpha = 1;
            self.card.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)dismissAnimated:(BOOL)animated {
    if (!animated) {
        [self removeFromSuperview];
        return;
    }
    CGFloat H = CGRectGetHeight(self.card.bounds);
    [UIView animateWithDuration:0.22
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.alpha = 0;
        self.card.transform = CGAffineTransformMakeTranslation(0, H);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
