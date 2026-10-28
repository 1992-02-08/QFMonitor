//
//  QFLog.m
//

#import "QFLog.h"
#import <stdarg.h>
#import <unistd.h>

static NSString *QFTimeStamp(void) {
    static NSDateFormatter *fmt = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss.SSS";
    });
    return [fmt stringFromDate:[NSDate date]];
}

void QFLog(NSString *format, ...) {
    va_list ap;
    va_start(ap, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);

    NSString *line = [NSString stringWithFormat:@"[%@ pid=%d uid=%d euid=%d] %@\n",
                      QFTimeStamp(), getpid(), getuid(), geteuid(), msg];

    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    NSString *path = QF_LOG_PATH;

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [data writeToFile:path atomically:NO];
        return;
    }

    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) {
        // 权限不足等, 退回整体写
        NSString *old = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
        [[old stringByAppendingString:line] writeToFile:path
                                              atomically:NO
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
        return;
    }
    @try {
        [fh seekToEndOfFile];
        [fh writeData:data];
    } @catch (NSException *e) {
        // ignore
    }
    [fh closeFile];
}

void QFLogReset(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:QF_LOG_PATH error:nil];
    QFLog(@"===== log reset =====");
}
