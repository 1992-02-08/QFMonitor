//
//  QFAppDelegate.m
//

#import "QFAppDelegate.h"
#import "QFMonitorController.h"

@implementation QFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [QFMonitorController shared];
    [self.window makeKeyAndVisible];
    return YES;
}

@end