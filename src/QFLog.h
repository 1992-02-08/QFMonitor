//
//  QFLog.h — HUD 进程诊断日志（写文件，启动器页面可读）
//

#import <Foundation/Foundation.h>

#define QF_LOG_PATH_C "/var/mobile/Library/Caches/com.qfmonitor.hud.log"
#define QF_LOG_PATH   @"/var/mobile/Library/Caches/com.qfmonitor.hud.log"

// 追加一行日志: [pid uid 时间] 内容
void QFLog(NSString *fmt, ...) NS_FORMAT_FUNCTION(1, 2);

// 清空日志（每次启动 HUD 时调用）
void QFLogReset(void);
