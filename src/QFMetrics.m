//
//  QFMetrics.m
//

#import "QFMetrics.h"

#import <IOKit/IOKitLib.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <ifaddrs.h>
#import <net/if.h>
#import <limits.h>

@implementation QFMetrics {
    io_service_t   _batSvc;
    natural_t      _pTotal;
    natural_t      _pIdle;
    uint64_t       _pIn;
    uint64_t       _pOut;
    BOOL           _netPrimed;
    CADisplayLink  *_displayLink;
    NSInteger       _fpsFrames;
    CFTimeInterval  _fpsStart;
    double         _smoothDown;
    double         _smoothUp;
}

+ (instancetype)shared {
    static QFMetrics *m = nil;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ m = [[QFMetrics alloc] init]; });
    return m;
}

- (instancetype)init {
    if (self = [super init]) {
        _smoothDown = 0;
        _smoothUp = 0;
        _fpsStart = CACurrentMediaTime();
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        [self startDisplayLink];
    }
    return self;
}

#pragma mark - 采样入口

- (void)sampleAll {
    [self sampleNet];
    [self sampleCPU];
    [self sampleBattery];
    [self sampleBatteryDetail];
}

#pragma mark - 网络

- (void)sampleNet {
    struct ifaddrs *ifa = NULL, *p;
    if (getifaddrs(&ifa) != 0 || !ifa) return;

    uint64_t tin = 0, tout = 0;
    for (p = ifa; p; p = p->ifa_next) {
        if (!p->ifa_data || !(p->ifa_flags & IFF_UP)) continue;
        if (p->ifa_flags & IFF_LOOPBACK) continue;
        const char *n = p->ifa_name ? p->ifa_name : "";
        if (!strncmp(n, "lo", 2)     || !strncmp(n, "awdl", 4) ||
            !strncmp(n, "bridge", 6) || !strncmp(n, "utun", 4) ||
            !strncmp(n, "ipsec", 5)  || !strncmp(n, "tap", 3)) continue;
        struct if_data *d = (struct if_data *)p->ifa_data;
        tin  += d->ifi_ibytes;
        tout += d->ifi_obytes;
    }
    freeifaddrs(ifa);

    if (_netPrimed && tin >= _pIn && tout >= _pOut) {
        double d = (double)(tin  - _pIn);
        double u = (double)(tout - _pOut);
        // 指数平滑, 数值不至于乱跳
        _smoothDown = _smoothDown * 0.4 + d * 0.6;
        _smoothUp   = _smoothUp   * 0.4 + u * 0.6;
        self.downBps = _smoothDown;
        self.upBps   = _smoothUp;
    }
    _pIn = tin; _pOut = tout; _netPrimed = YES;
}

#pragma mark - CPU

- (void)sampleCPU {
    host_cpu_load_info_data_t cpu;
    mach_msg_type_number_t cnt = HOST_CPU_LOAD_INFO_COUNT;
    if (host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO,
                        (host_info_t)&cpu, &cnt) != KERN_SUCCESS) return;
    natural_t idle  = cpu.cpu_ticks[CPU_STATE_IDLE];
    natural_t total = cpu.cpu_ticks[CPU_STATE_SYSTEM] + cpu.cpu_ticks[CPU_STATE_USER]
                    + idle + cpu.cpu_ticks[CPU_STATE_NICE];
    if (_pTotal && total > _pTotal) {
        natural_t dt = total - _pTotal;
        natural_t di = idle >= _pIdle ? idle - _pIdle : 0;
        double v = 100.0 * (double)(dt - di) / (double)dt;
        if (v >= 0 && v <= 100) self.cpuPercent = v;
    }
    _pTotal = total; _pIdle = idle;
}

#pragma mark - 电量

- (void)sampleBattery {
    UIDevice *d = [UIDevice currentDevice];
    float l = d.batteryLevel;
    if (l >= 0) self.batteryPercent = (int)lroundf(l * 100.0f);
    UIDeviceBatteryState s = d.batteryState;
    self.charging = (s == UIDeviceBatteryStateCharging || s == UIDeviceBatteryStateFull);
}

#pragma mark - 电池温度 / 功率 (IOKit AppleSmartBattery)

- (long long)batInt:(NSString *)key def:(long long)def {
    @try {
        if (!_batSvc) {
            // iOS SDK 把 kIOMasterPortDefault 标为 unavailable, 直接给 0 等价默认端口
            _batSvc = IOServiceGetMatchingService((mach_port_t)0,
                                                  IOServiceMatching("AppleSmartBattery"));
        }
        if (!_batSvc) return def;
        CFTypeRef v = IORegistryEntryCreateCFProperty(_batSvc,
                        (__bridge CFStringRef)key, kCFAllocatorDefault, 0);
        if (!v) return def;
        long long r = def;
        if (CFGetTypeID(v) == CFNumberGetTypeID()) {
            long long n = 0;
            if (CFNumberGetValue((CFNumberRef)v, kCFNumberLongLongType, &n)) r = n;
        }
        CFRelease(v);
        return r;
    } @catch (NSException *e) { }
    return def;
}

- (void)sampleBatteryDetail {
    long long raw = 0;
    NSArray *tkeys = @[@"Temperature", @"VirtualTemperature", @"BatteryTemp", @"BatteryTemperature"];
    for (NSString *k in tkeys) {
        raw = [self batInt:k def:0];
        if (raw > 0) break;
    }
    double t = -999.0;
    if (raw > 0) {
        double c1 = raw / 10.0;               // 0.1℃ 单位
        double c2 = raw / 100.0 - 273.15;     // 0.01K 单位
        if (c1 > -5.0 && c1 < 80.0)      t = c1;
        else if (c2 > -5.0 && c2 < 80.0) t = c2;
    }
    self.temperatureC = t;

    double v = (double)[self batInt:@"Voltage" def:0];            // mV
    long long i = [self batInt:@"InstantAmperage" def:LLONG_MIN];  // mA(负=放电)
    if (i == LLONG_MIN) i = [self batInt:@"Amperage" def:0];
    if (i != LLONG_MIN && i != 0) {
        self.currentMa = (double)i;
        self.currentValid = YES;
    } else {
        self.currentValid = NO;
    }
    if (v > 100.0 && v < 10000.0) {
        self.watt = (v * (double)i) / 1000000.0;
        self.wattValid = YES;
    } else {
        self.wattValid = NO;
    }
}

#pragma mark - FPS (CADisplayLink 累计)

- (void)startDisplayLink {
    if (_displayLink) return;
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onFrame:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)onFrame:(CADisplayLink *)link {
    _fpsFrames++;
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval dt = now - _fpsStart;
    if (dt >= 0.5) {
        self.fps = (double)_fpsFrames / dt;
        _fpsFrames = 0;
        _fpsStart = now;
    }
}

#pragma mark - 格式化

+ (NSString *)formatRate:(double)bps {
    if (bps < 0) bps = 0;
    if (bps >= 1048576.0) return [NSString stringWithFormat:@"%.1fM", bps / 1048576.0];
    if (bps >= 1024.0)    return [NSString stringWithFormat:@"%.0fK", bps / 1024.0];
    return [NSString stringWithFormat:@"%.0fB", bps];
}

@end
