//
//  QFPrefs.m
//

#import "QFPrefs.h"

#define K_SZ      @"qf.fontSize"
#define K_SC      @"qf.scaleFactor"
#define K_CPU     @"qf.showCPU"
#define K_FPS     @"qf.showFPS"
#define K_DN      @"qf.showDown"
#define K_UP      @"qf.showUp"
#define K_BAT     @"qf.showBattery"
#define K_TMP     @"qf.showTemp"
#define K_PWR     @"qf.showPower"
#define K_PX      @"qf.posX"
#define K_PY      @"qf.posY"
#define K_PT      @"qf.passthrough"

@implementation QFPrefs

+ (instancetype)shared {
    static QFPrefs *p;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ p = [[QFPrefs alloc] init]; [p load]; });
    return p;
}

- (void)load {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];

    _fontSize = [d floatForKey:K_SZ];
    if (_fontSize < 8 || _fontSize > 24) _fontSize = 11;

    _scaleFactor = [d floatForKey:K_SC];
    if (_scaleFactor < 0.6 || _scaleFactor > 2.0) _scaleFactor = 1.0;

    _showCPU    = [d objectForKey:K_CPU] ? [d boolForKey:K_CPU] : YES;
    _showFPS    = [d objectForKey:K_FPS] ? [d boolForKey:K_FPS] : YES;
    _showDown   = [d objectForKey:K_DN]  ? [d boolForKey:K_DN]  : YES;
    _showUp     = [d objectForKey:K_UP]  ? [d boolForKey:K_UP]  : YES;
    _showBattery= [d objectForKey:K_BAT] ? [d boolForKey:K_BAT] : YES;
    _showTemp   = [d objectForKey:K_TMP] ? [d boolForKey:K_TMP] : YES;
    _showPower  = [d objectForKey:K_PWR] ? [d boolForKey:K_PWR] : YES;

    float px = [d floatForKey:K_PX], py = [d floatForKey:K_PY];
    if ([d objectForKey:K_PX] && [d objectForKey:K_PY]) {
        _normalizedPosition = CGPointMake(px, py);
    } else {
        _normalizedPosition = CGPointMake(0.5, 0.3); // 顶中偏下
    }

    _passthrough = [d objectForKey:K_PT] ? [d boolForKey:K_PT] : NO;
}

- (void)save {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setFloat:_fontSize forKey:K_SZ];
    [d setFloat:_scaleFactor forKey:K_SC];
    [d setBool:_showCPU forKey:K_CPU];
    [d setBool:_showFPS forKey:K_FPS];
    [d setBool:_showDown forKey:K_DN];
    [d setBool:_showUp forKey:K_UP];
    [d setBool:_showBattery forKey:K_BAT];
    [d setBool:_showTemp forKey:K_TMP];
    [d setBool:_showPower forKey:K_PWR];
    [d setFloat:_normalizedPosition.x forKey:K_PX];
    [d setFloat:_normalizedPosition.y forKey:K_PY];
    [d setBool:_passthrough forKey:K_PT];
    [d synchronize];
}

+ (CGFloat)presetSize:(NSInteger)idx {
    switch (idx) {
        case 0: return 9.0;   // 小
        case 1: return 11.0;  // 标准
        case 2: return 14.0;  // 大
        case 3: default: return 18.0; // 特大
    }
}

@end