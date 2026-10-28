//
//  QFMetrics.h
//  悬浮监控数据采集中心。
//
//  CPU / FPS / 上下行网络 / 电量 / 温度 / 功率 定时采集。
//  （GPU 已按需求移除）
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QFMetrics : NSObject

// 单例
+ (instancetype)shared;

// 输出值
@property (nonatomic, assign, readonly) CGFloat cpuPercent;   // CPU %
@property (nonatomic, assign, readonly) NSInteger fps;        // 帧率
@property (nonatomic, assign, readonly) double downBps;       // 下行 B/s
@property (nonatomic, assign, readonly) double upBps;         // 上行 B/s
@property (nonatomic, assign, readonly) NSInteger batteryLevel; // 电量 %
@property (nonatomic, assign, readonly) BOOL    charging;     // 是否充电

// 温度 / 功率（IOKit 电池数据，可能无效）
@property (nonatomic, assign, readonly) NSInteger temperature; // 温度 °C（<=-1000 表示无数据）
@property (nonatomic, assign, readonly) BOOL    wattValid;     // 功率数据是否有效
@property (nonatomic, assign, readonly) double  watt;          // 功率 W

// 启动/停止采集
- (void)startSampling;
- (void)stopSampling;

@end