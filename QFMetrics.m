//
//  QFMetrics.m
//  数据采集实现。
//

#import "QFMetrics.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <mach/mach_time.h>
#import <sys/sysctl.h>
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_var.h>   // ifaddrs
#import <ifaddrs.h>
#import <IOKit/IOKitLib.h>
#import <QuartzCore/QuartzCore.h>

@interface QFMetrics ()
@property (nonatomic, assign, readwrite) CGFloat cpuPercent;
@property (nonatomic, assign, readwrite) NSInteger fps;
@property (nonatomic, assign, readwrite) double downBps;
@property (nonatomic, assign, readwrite) double upBps;
@property (nonatomic, assign, readwrite) NSInteger batteryLevel;
@property (nonatomic, assign, readwrite) BOOL charging;
@property (nonatomic, assign, readwrite) NSInteger temperature;
@property (nonatomic, assign, readwrite) BOOL wattValid;
@property (nonatomic, assign, readwrite) double watt;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) CADisplayLink *displayLink;

// CPU 差值
@property (nonatomic, assign) uint64_t lastCPUTotal;
@property (nonatomic, assign) uint64_t lastCPUTicks;

// 网络累计 & EMA 平滑
@property (nonatomic, assign) uint64_t lastDownBytes;
@property (nonatomic, assign) uint64_t lastUpBytes;
@property (nonatomic, assign) NSTimeInterval lastNetStamp;
@property (nonatomic, assign) double emaDown;
@property (nonatomic, assign) double emaUp;
@end

@implementation QFMetrics

+ (instancetype)shared {
    static QFMetrics *m;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ m = [[QFMetrics alloc] init]; });
    return m;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _temperature = -9999;   // 无数据哨兵
        _wattValid = NO;
        _fps = 0;
        _cpuPercent = 0;
        _downBps = 0;
        _upBps = 0;
        _batteryLevel = -1;
    }
    return self;
}

- (void)startSampling {
    if (self.timer) return;

    // 网络基线（避免首次差值过大）
    [self sampleNetReset];
    [self sampleBattery];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(sampleAllOnce)
                                                userInfo:nil
                                                 repeats:YES];

    // FPS 用 CADisplayLink 精确计帧
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_fpsTick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopSampling {
    [self.timer invalidate]; self.timer = nil;
    [self.displayLink invalidate]; self.displayLink = nil;
}

- (void)sampleAllOnce {
    [self sampleCPU];
    [self sampleBattery];
    [self sampleNet];
    [self sampleBatteryDetail];
}

#pragma mark - CPU

- (void)sampleCPU {
    host_cpu_load_info_data_t info;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    kern_return_t kr = host_statistics(mach_host_self(),
                                       HOST_CPU_LOAD_INFO,
                                       (host_info_t)&info,
                                       &count);
    if (kr != KERN_SUCCESS) return;

    uint64_t total = 0;
    for (int i = 0; i < CPU_STATE_MAX; i++) total += info.cpu_ticks[i];
    uint64_t ticks = info.cpu_ticks[CPU_STATE_USER] + info.cpu_ticks[CPU_STATE_SYSTEM];

    if (self.lastCPUTicks) {
        uint64_t dt = total - self.lastCPUTotal;
        uint64_t dtk = ticks - self.lastCPUTicks;
        if (dt > 0) {
            double v = (double)dtk / (double)dt * 100.0;
            v = v * [self _activeCoresFactor];
            if (v >= 0 && v <= 100) self.cpuPercent = v;
        }
    }
    self.lastCPUTotal = total;
    self.lastCPUTicks = ticks;
}

- (double)_activeCoresFactor {
    // 以 4 核为基准的占比标定（视觉友好）
    int nc = (int)[NSProcessInfo processInfo].activeProcessorCount;
    if (nc < 1) return 1.0;
    return 4.0 / nc;
}

#pragma mark - FPS

- (void)_fpsTick:(CADisplayLink *)link {
    static NSTimeInterval last;
    NSTimeInterval now = CACurrentMediaTime();
    if (last > 0) {
        double secs = now - last;
        if (secs > 0) self.fps = (NSInteger)lround(1.0 / secs);
    }
    last = now;
}

#pragma mark - Battery

- (void)sampleBattery {
    UIDevice *dev = [UIDevice currentDevice];
    [dev setBatteryMonitoringEnabled:YES];
    float lvl = dev.batteryLevel;
    if (lvl >= 0) self.batteryLevel = (NSInteger)(lvl * 100.0);
    self.charging = (dev.batteryState == UIDeviceBatteryStateCharging);
}

#pragma mark - Network

- (void)sampleNetReset {
    [self _readNetTotals:&_lastDownBytes up:&_lastUpBytes];
    _lastNetStamp = [NSDate timeIntervalSinceReferenceDate];
    _emaDown = 0; _emaUp = 0;
}

- (void)sampleNet {
    uint64_t d = 0, u = 0;
    [self _readNetTotals:&d up:&u];

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval dt = now - self.lastNetStamp;
    if (dt <= 0) { self.lastNetStamp = now; return; }

    double rawDown = (double)(d - self.lastDownBytes) / dt; // B/s
    double rawUp   = (double)(u - self.lastUpBytes)   / dt;

    // EMA 平滑（≈0.6）
    const double a = 0.6;
    self.emaDown = self.emaDown == 0 ? rawDown : self.emaDown * (1 - a) + rawDown * a;
    self.emaUp   = self.emaUp   == 0 ? rawUp   : self.emaUp   * (1 - a) + rawUp   * a;

    self.downBps = self.emaDown;
    self.upBps   = self.emaUp;

    self.lastDownBytes = d; self.lastUpBytes = u; self.lastNetStamp = now;
}

- (void)_readNetTotals:(uint64_t *)down up:(uint64_t *)up {
    uint64_t d = 0, u = 0;
    struct ifaddrs *ifap = NULL;
    if (getifaddrs(&ifap) == 0) {
        const struct ifaddrs *ifa;
        for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
            if (!ifa->ifa_addr) continue;
            if (!(ifa->ifa_flags & IFF_UP)) continue;
            if (!(ifa->ifa_flags & IFF_RUNNING)) continue;
            if (ifa->ifa_addr->sa_family != AF_LINK) continue;

            NSString *name = ifa->ifa_name ? [NSString stringWithUTF8String:ifa->ifa_name] : @"";
            // 排除回环/awdl/桥接/隧道/ipsec
            if ([name isEqualToString:@"lo"]) continue;
            if ([name hasPrefix:@"awdl"]) continue;
            if ([name hasPrefix:@"bridge"]) continue;
            if ([name hasPrefix:@"utun"]) continue;
            if ([name hasPrefix:@"ipsec"]) continue;

            struct if_data *stat = (struct if_data *)ifa->ifa_data;
            if (stat) {
                d += stat->ifi_ibytes;
                u += stat->ifi_obytes;
            }
        }
        freeifaddrs(ifap);
    }
    if (down) *down = d;
    if (up)   *up = u;
}

#pragma mark - Battery detail (temp / power via IOKit)

- (void)sampleBatteryDetail {
    io_service_t service = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                       IOServiceMatching("AppleSmartBattery"));
    if (service == MACH_PORT_NULL) {
        self.temperature = -9999;
        self.wattValid = NO;
        return;
    }

    NSInteger temp = -9999;
    BOOL haveV = NO, haveI = NO;
    int voltmV = 0, curmA = 0;

    CFTypeRef tempRef = IORegistryEntryCreateCFProperty(service, CFSTR("Temperature"), kCFAllocatorDefault, 0);
    if (tempRef) {
        if (CFGetTypeID(tempRef) == CFNumberGetTypeID()) {
            int v = 0;
            if (CFNumberGetValue(tempRef, kCFNumberIntType, &v)) temp = v / 10; // 0.1°C -> °C
        }
        CFRelease(tempRef);
    }

    CFTypeRef voltRef = IORegistryEntryCreateCFProperty(service, CFSTR("Voltage"), kCFAllocatorDefault, 0);
    if (voltRef) {
        if (CFGetTypeID(voltRef) == CFNumberGetTypeID()) {
            CFNumberGetValue(voltRef, kCFNumberIntType, &voltmV);
            haveV = YES;
        }
        CFRelease(voltRef);
    }

    CFTypeRef ampRef = IORegistryEntryCreateCFProperty(service, CFSTR("InstantAmperage"), kCFAllocatorDefault, 0);
    if (ampRef) {
        if (CFGetTypeID(ampRef) == CFNumberGetTypeID()) {
            CFNumberGetValue(ampRef, kCFNumberIntType, &curmA);
            haveI = YES;
        }
        CFRelease(ampRef);
    }

    // Power = V * I / 1e6 (mV * mA -> uW -> W)
    if (haveV && haveI) {
        self.watt = (double)voltmV * (double)curmA / 1e6;
        self.wattValid = YES;
    } else {
        self.wattValid = NO;
    }
    self.temperature = temp;
    IOObjectRelease(service);
}

@end