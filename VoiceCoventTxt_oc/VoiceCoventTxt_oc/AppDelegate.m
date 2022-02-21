//
//  AppDelegate.m
//  VoiceCoventTxt_oc
//
//  Created by facilityone on 2022/2/16.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  
    self.window.rootViewController=[[UINavigationController alloc]initWithRootViewController:[ViewController new]];

    [self.window makeKeyAndVisible];

    return YES;
}



@end
