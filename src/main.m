//
//  main.m — 入口
//
//    无参数      -> 启动器界面(App 主界面)
//    -hud        -> HUD 插件进程(全局悬浮窗)
//    -exit       -> 结束 HUD 进程
//    -check      -> 查询 HUD 进程是否在运行 (退出码 0=未运行, 1=运行中)
//

#import <UIKit/UIKit.h>
#import <signal.h>
#import <unistd.h>
#import <stdlib.h>
#import <string.h>

#import "QFHUD.h"
#import "QFLauncher.h"

#define QF_PID_PATH_C "/var/mobile/Library/Caches/com.qfmonitor.hud.pid"
#define QF_PID_PATH   @"/var/mobile/Library/Caches/com.qfmonitor.hud.pid"

#pragma mark - 启动器 Delegate

@interface QFAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation QFAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor colorWithRed:0.055 green:0.063 blue:0.082 alpha:1.0];
    self.window.rootViewController = [[QFLauncherController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end

#pragma mark - main

int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc > 1) {
            if (strcmp(argv[1], "-hud") == 0) {
                return QFRunHUDProcess();
            }
            if (strcmp(argv[1], "-exit") == 0) {
                NSString *pidStr = [NSString stringWithContentsOfFile:QF_PID_PATH
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
                if (pidStr.length) {
                    pid_t pid = (pid_t)[pidStr intValue];
                    if (pid > 0) kill(pid, SIGKILL);
                }
                unlink(QF_PID_PATH_C);
                return EXIT_SUCCESS;
            }
            if (strcmp(argv[1], "-check") == 0) {
                NSString *pidStr = [NSString stringWithContentsOfFile:QF_PID_PATH
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
                if (pidStr.length) {
                    pid_t pid = (pid_t)[pidStr intValue];
                    int r = kill(pid, 0);
                    return (r == 0 ? EXIT_FAILURE : EXIT_SUCCESS);
                }
                return EXIT_SUCCESS;
            }
        }
        return UIApplicationMain(argc, argv, nil, @"QFAppDelegate");
    }
}
