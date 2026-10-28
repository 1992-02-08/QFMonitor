//
//  QFMetrics.h — 数据采集(网速 / 电量 / 温度 / 功率 / CPU / FPS)
//
//  采集逻辑沿用之前注入版的实现, 这里独立成类, 便于 UI 层解耦。
//
#ifndef QFMETRICS_H
#define QFMETRICS_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QFMetrics : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) double downBps;        // 字节/秒
@property (nonatomic, assign) double upBps;          // 字节/秒
@property (nonatomic, assign) double cpuPercent;     // 0~100
@property (nonatomic, assign) double fps;            // 帧率
@property (nonatomic, assign) int    batteryPercent; // 0~100
@property (nonatomic, assign) BOOL   charging;       // 是否在充电
@property (nonatomic, assign) double temperatureC;   // 摄氏度, < -100 表示读不到
@property (nonatomic, assign) double watt;           // W, 负=放电 正=充电
@property (nonatomic, assign) BOOL   wattValid;
@property (nonatomic, assign) double currentMa;            // 电流 mA, 负=放电 正=充电
@property (nonatomic, assign) BOOL   currentValid;

- (void)sampleAll;                                   // 采样一轮
+ (NSString *)formatRate:(double)bps;                 // 12.3M / 98K / 12B

@end

#endif /* QFMETRICS_H */
