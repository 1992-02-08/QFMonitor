//
//  QFLauncher.m
//

#import "QFLauncher.h"
#import "QFHUD.h"
#import "QFPrefs.h"

@interface QFLauncherController ()
@property (nonatomic, strong) UILabel  *statusLabel;
@property (nonatomic, strong) UILabel  *pidLabel;
@property (nonatomic, strong) UIButton *primaryButton;
@property (nonatomic, strong) UISwitch *passSwitch;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation QFLauncherController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.055 green:0.063 blue:0.082 alpha:1.0];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] initWithFrame:CGRectZero];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.alignment = UIStackViewAlignmentFill;
    [scroll addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:24],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-32],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:22],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-22],
    ]];

    // ---------- 头部 ----------
    UIView *header = [[UIView alloc] initWithFrame:CGRectZero];
    [header.heightAnchor constraintEqualToConstant:104].active = YES;

    UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectZero];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:46 weight:UIImageSymbolWeightSemibold];
    icon.image = [UIImage systemImageNamed:@"gauge.with.dots.needle.67percent"
                      withConfiguration:cfg];
    icon.tintColor = [UIColor colorWithRed:0.36 green:0.86 blue:1.00 alpha:1.0];
    [header addSubview:icon];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"QFMonitor";
    title.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    title.textColor = [UIColor whiteColor];
    [header addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectZero];
    sub.translatesAutoresizingMaskIntoConstraints = NO;
    sub.text = @"单行网速悬浮窗 · 无背景 · 自绘面板";
    sub.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    sub.textColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    [header addSubview:sub];

    [NSLayoutConstraint activateConstraints:@[
        [icon.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:56],
        [icon.heightAnchor constraintEqualToConstant:56],

        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:14],
        [title.topAnchor constraintEqualToAnchor:header.topAnchor constant:16],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor],

        [sub.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [sub.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:4],
        [sub.trailingAnchor constraintLessThanOrEqualToAnchor:header.trailingAnchor],
    ]];

    [stack addArrangedSubview:header];

    // ---------- 状态卡 ----------
    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    card.layer.cornerRadius = 16;
    [card.heightAnchor constraintEqualToConstant:96].active = YES;

    UILabel *cap = [[UILabel alloc] initWithFrame:CGRectZero];
    cap.translatesAutoresizingMaskIntoConstraints = NO;
    cap.text = @"悬浮窗状态";
    cap.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    cap.textColor = [UIColor colorWithWhite:1.0 alpha:0.55];
    [card addSubview:cap];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.text = @"检测中…";
    _statusLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    _statusLabel.textColor = [UIColor whiteColor];
    [card addSubview:_statusLabel];

    _pidLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _pidLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _pidLabel.font = [UIFont monospacedDigitSystemFontOfSize:11.5 weight:UIFontWeightRegular];
    _pidLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
    _pidLabel.text = @" ";
    [card addSubview:_pidLabel];

    [NSLayoutConstraint activateConstraints:@[
        [cap.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [cap.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],

        [_statusLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_statusLabel.topAnchor constraintEqualToAnchor:cap.bottomAnchor constant:4],
        [_statusLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],

        [_pidLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [_pidLabel.topAnchor constraintEqualToAnchor:_statusLabel.bottomAnchor constant:2],
        [_pidLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];

    [stack addArrangedSubview:card];

    // ---------- 主按钮 ----------
    _primaryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _primaryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_primaryButton setTitle:@"启动悬浮窗" forState:UIControlStateNormal];
    _primaryButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [_primaryButton setTitleColor:[UIColor colorWithRed:0.04 green:0.10 blue:0.14 alpha:1.0]
                         forState:UIControlStateNormal];
    _primaryButton.backgroundColor = [UIColor colorWithRed:0.36 green:0.86 blue:1.00 alpha:1.0];
    _primaryButton.layer.cornerRadius = 15;
    _primaryButton.layer.masksToBounds = YES;
    [_primaryButton addTarget:self action:@selector(onPrimary) forControlEvents:UIControlEventTouchUpInside];
    [_primaryButton.heightAnchor constraintEqualToConstant:54].active = YES;
    [stack addArrangedSubview:_primaryButton];

    // ---------- 次按钮 ----------
    UIButton *stop = [UIButton buttonWithType:UIButtonTypeSystem];
    stop.translatesAutoresizingMaskIntoConstraints = NO;
    [stop setTitle:@"结束悬浮窗" forState:UIControlStateNormal];
    stop.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [stop setTitleColor:[UIColor colorWithRed:1.0 green:0.45 blue:0.45 alpha:1.0]
               forState:UIControlStateNormal];
    stop.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    stop.layer.cornerRadius = 13;
    stop.layer.masksToBounds = YES;
    [stop addTarget:self action:@selector(onStop) forControlEvents:UIControlEventTouchUpInside];
    [stop.heightAnchor constraintEqualToConstant:46].active = YES;
    [stack addArrangedSubview:stop];

    // ---------- 触摸穿透 ----------
    UIView *ptRow = [[UIView alloc] initWithFrame:CGRectZero];
    ptRow.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.07];
    ptRow.layer.cornerRadius = 13;
    [ptRow.heightAnchor constraintEqualToConstant:52].active = YES;

    UILabel *ptLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    ptLabel.translatesAutoresizingMaskIntoConstraints = NO;
    ptLabel.text = @"触摸穿透";
    ptLabel.font = [UIFont systemFontOfSize:14.5 weight:UIFontWeightRegular];
    ptLabel.textColor = [UIColor whiteColor];
    [ptRow addSubview:ptLabel];

    _passSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    _passSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    _passSwitch.onTintColor = [UIColor colorWithRed:0.36 green:0.86 blue:1.00 alpha:1.0];
    _passSwitch.on = [QFPrefs shared].passthrough;
    [_passSwitch addTarget:self action:@selector(onPassthrough) forControlEvents:UIControlEventValueChanged];
    [ptRow addSubview:_passSwitch];

    [NSLayoutConstraint activateConstraints:@[
        [ptLabel.leadingAnchor constraintEqualToAnchor:ptRow.leadingAnchor constant:16],
        [ptLabel.centerYAnchor constraintEqualToAnchor:ptRow.centerYAnchor],
        [_passSwitch.trailingAnchor constraintEqualToAnchor:ptRow.trailingAnchor constant:-16],
        [_passSwitch.centerYAnchor constraintEqualToAnchor:ptRow.centerYAnchor],
    ]];
    [stack addArrangedSubview:ptRow];

    // ---------- 说明 ----------
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectZero];
    tip.text = @"· 悬浮条为一行纯文字，没有任何底卡或描边\n"
                "· 拖动可自由移动，点齿轮打开设置（字号 / 缩放 / 显示项 / 配色）\n"
                "· 若点击没有反应，可在此关闭「触摸穿透」后再点悬浮条";
    tip.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    tip.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
    tip.numberOfLines = 0;
    [stack addArrangedSubview:tip];

    // ---------- 诊断日志 ----------
    UILabel *diagCap = [[UILabel alloc] initWithFrame:CGRectZero];
    diagCap.text = @"HUD 诊断日志";
    diagCap.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    diagCap.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [stack addArrangedSubview:diagCap];

    _diagLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _diagLabel.font = [UIFont monospacedSystemFontOfSize:9.5 weight:UIFontWeightRegular];
    _diagLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.72];
    _diagLabel.numberOfLines = 0;
    _diagLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.05];
    _diagLabel.layer.cornerRadius = 10;
    _diagLabel.layer.masksToBounds = YES;
    _diagLabel.text = @"（点「重启悬浮窗」后查看）";
    [stack addArrangedSubview:_diagLabel];

    [self refreshStatus];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refreshStatus];
    if (![QFPrefs shared].passthrough) {
        _passSwitch.on = NO;
    }
    // 首次进入自动启动
    static BOOL didAutoStart = NO;
    if (!didAutoStart) {
        didAutoStart = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (!QFIsHUDRunning()) {
                QFStartHUD();
                [self refreshStatus];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [self refreshDiagLog];
                });
            }
        });
    }
}

#pragma mark - 动作

- (void)refreshStatus {
    BOOL running = QFIsHUDRunning();
    if (running) {
        _statusLabel.text = @"运行中";
        _statusLabel.textColor = [UIColor colorWithRed:0.40 green:0.92 blue:0.60 alpha:1.0];
        [_primaryButton setTitle:@"重启悬浮窗" forState:UIControlStateNormal];
    } else {
        _statusLabel.text = @"未运行";
        _statusLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [_primaryButton setTitle:@"启动悬浮窗" forState:UIControlStateNormal];
    }

    NSString *pid = [NSString stringWithContentsOfFile:@"/var/mobile/Library/Caches/com.qfmonitor.hud.pid"
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    _pidLabel.text = pid.length ? [NSString stringWithFormat:@"HUD PID %@", pid] : @" ";

    [self refreshDiagLog];
}

- (void)refreshDiagLog {
    if (!_diagLabel) return;
    NSString *log = [NSString stringWithContentsOfFile:@"/var/mobile/Library/Caches/com.qfmonitor.hud.log"
                                             encoding:NSUTF8StringEncoding
                                                error:nil];
    if (log.length == 0) {
        _diagLabel.text = @"（无日志 — HUD 进程可能根本没启动）";
        return;
    }
    // 只取最后 2200 字符, 避免页面过长
    if (log.length > 2200) {
        log = [@"...(前略)\n" stringByAppendingString:[log substringFromIndex:log.length - 2200]];
    }
    _diagLabel.text = log;
}

- (void)onPrimary {
    _primaryButton.enabled = NO;
    [_primaryButton setTitle:@"处理中…" forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        QFStopHUD();
        usleep(300000);
        QFStartHUD();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            self->_primaryButton.enabled = YES;
            [self refreshStatus];
            // 2.5 秒后再刷一次日志, 等 HUD 走完启动流程
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self refreshDiagLog];
            });
        });
    });
}

- (void)onStop {
    QFStopHUD();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self refreshStatus];
    });
}

- (void)onPassthrough {
    QFPrefs *p = [QFPrefs shared];
    p.passthrough = _passSwitch.isOn;
    [p save];
}

@end
