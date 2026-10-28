# QFMonitor · 悬浮监控条

单条横排悬浮监控 App（越狱机 IPA）。**无 GPU 采集**（按需求移除）。

## 显示内容
CPU% · FPS · ↓下行 · ↑上行 · 电量%(充电⚡) · 温度° · 功率W

## 特性
- **全透明无背景**：无卡片、无线、无圆角、无阴影层；仅文字带紧贴阴影（blur 1.2，零偏移）
- **文字尺寸紧贴内容**，高度包裹文字
- **整体可拖拽**，横竖屏通用；位置以归一化坐标存储，旋转不漂移
- **右侧小齿轮** + **双击整条** → 打开设置
- **底部抽屉设置面板**（仅顶部两角圆角，76% 屏高，可滚动，改动即时生效并持久化）：
  - 实时预览
  - 字号滑杆 8–24pt + 4 档预设（小9 / 标准11 / 大14 / 特大18）
  - 整体缩放 0.6×–2.0×
  - CPU / FPS / 下行 / 上行 / 电量 / 温度 / 功率 显示开关
  - 位置重置到顶中
  - 触摸穿透开关
  - 结束悬浮窗 / 退出 App

## 数据来源
| 指标 | 实现 |
|------|------|
| CPU | host_statistics(HOST_CPU_LOAD_INFO) 差值 ×100，按活跃核标定 |
| FPS | CADisplayLink 计帧 |
| 上下行 | getifaddrs 排除 lo/awdl/bridge/utun/ipsec，EMA(≈0.6) 平滑 |
| 电量 | UIDevice batteryLevel/State |
| 温度/功率 | IOKit 读 AppleSmartBattery（Temperature/Voltage/InstantAmperage），功率=V×I/1e6 W |

## 目录结构
```
main.m  QFAppDelegate  QFMonitorController  QFRowView  QFPanelView  QFMetrics  QFPrefs
```

## 编译
用 theos：`make`（产物 `.app`，可签名打 IPA）。
云端已配置 GitHub Actions（见 `.github/workflows`），推送 main 分支自动编译并上传 `.ipa` 附件。

## 注意
IPA 为 ad-hoc/ldid 自签，仅适用于**越狱设备**。