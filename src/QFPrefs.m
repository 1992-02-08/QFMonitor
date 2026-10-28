//
//  QFPrefs.m
//

#import "QFPrefs.h"

NSString *const QFPrefsPath = @"/var/mobile/Library/Preferences/com.qfmonitor.hud.plist";

@implementation QFPrefs {
    NSDate *_lastMod;
}

+ (instancetype)shared {
    static QFPrefs *p = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ p = [[QFPrefs alloc] init]; });
    return p;
}

- (instancetype)init {
    if (self = [super init]) {
        [self load];
    }
    return self;
}

- (void)load {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:QFPrefsPath];
    if (![d isKindOfClass:[NSDictionary class]]) d = @{};

    self.fontSize = [self num:d[@"fontSize"] def:11.0];
    if (self.fontSize < 8.0)  self.fontSize = 8.0;
    if (self.fontSize > 24.0) self.fontSize = 24.0;

    self.scale = [self num:d[@"scale"] def:1.0];
    if (self.scale < 0.6)  self.scale = 0.6;
    if (self.scale > 2.0)  self.scale = 2.0;

    self.showDown    = [self bool:d[@"showDown"]    def:YES];
    self.showUp      = [self bool:d[@"showUp"]      def:YES];
    self.showBattery = [self bool:d[@"showBattery"] def:YES];
    self.showTemp    = [self bool:d[@"showTemp"]    def:YES];
    self.showPower   = [self bool:d[@"showPower"]   def:YES];
    self.showCurrent = [self bool:d[@"showCurrent"] def:YES];
    self.showCPU     = [self bool:d[@"showCPU"]     def:YES];
    self.showFPS     = [self bool:d[@"showFPS"]     def:YES];

    self.posX = [self num:d[@"posX"] def:0.5];
    self.posY = [self num:d[@"posY"] def:0.14];
    if (self.posX < 0) self.posX = 0;
    if (self.posX > 1) self.posX = 1;
    if (self.posY < 0) self.posY = 0;
    if (self.posY > 1) self.posY = 1;

    self.accent = (NSInteger)[self num:d[@"accent"] def:0.0];
    if (self.accent < 0) self.accent = 0;
    if (self.accent > 5) self.accent = 5;

    self.passthrough = [self bool:d[@"passthrough"] def:YES];
    self.locked   = [self bool:d[@"locked"]   def:NO];
    self.freeDrag = [self bool:d[@"freeDrag"] def:YES];

    _lastMod = [self fileModDate];
}

- (void)save {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[@"fontSize"]   = @(self.fontSize);
    d[@"scale"]      = @(self.scale);
    d[@"showDown"]   = @(self.showDown);
    d[@"showUp"]     = @(self.showUp);
    d[@"showBattery"]= @(self.showBattery);
    d[@"showTemp"]   = @(self.showTemp);
    d[@"showPower"]  = @(self.showPower);
    d[@"showCurrent"]= @(self.showCurrent);
    d[@"showCPU"]    = @(self.showCPU);
    d[@"showFPS"]    = @(self.showFPS);
    d[@"posX"]       = @(self.posX);
    d[@"posY"]       = @(self.posY);
    d[@"accent"]     = @(self.accent);
    d[@"passthrough"]= @(self.passthrough);
    d[@"locked"]     = @(self.locked);
    d[@"freeDrag"]   = @(self.freeDrag);

    @try {
        NSString *dir = [QFPrefsPath stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        [d writeToFile:QFPrefsPath atomically:YES];
        // HUD 进程是 root 写的, 把 owner 改回 mobile, 让启动器 App 也能改
        [[NSFileManager defaultManager] setAttributes:@{
            NSFileOwnerAccountID: @501,
            NSFileGroupOwnerAccountID: @501,
        } ofItemAtPath:QFPrefsPath error:nil];
        _lastMod = [self fileModDate];
    } @catch (NSException *e) { }
}

- (NSDate *)fileModDate {
    NSDictionary *a = [[NSFileManager defaultManager] attributesOfItemAtPath:QFPrefsPath
                                                                       error:nil];
    return a[NSFileModificationDate];
}

- (BOOL)reloadIfChanged {
    NSDate *m = [self fileModDate];
    if (!m) return NO;
    if (_lastMod && [m isEqualToDate:_lastMod]) return NO;
    _lastMod = m;
    [self load];
    _lastMod = m;
    return YES;
}

- (void)resetPosition {
    self.posX = 0.5;
    self.posY = 0.14;
    [self save];
}

#pragma mark - 辅助

- (double)num:(id)v def:(double)def {
    if ([v isKindOfClass:[NSNumber class]]) return [v doubleValue];
    return def;
}

- (BOOL)bool:(id)v def:(BOOL)def {
    if ([v isKindOfClass:[NSNumber class]]) return [v boolValue];
    return def;
}

@end
