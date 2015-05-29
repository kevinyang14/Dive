//
//  AppDelegate.m
//  Dive
//
//  Created by Kevin Yang on 3/10/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "AppDelegate.h"
#import "Backendless.h"
#import "MediaService.h"
#import "WelcomeVC.h"
#import "DiveFeedTVC.h"
#import <Parse/Parse.h>

static NSString *APP_ID = @"28050D38-597E-D147-FFFE-6E7FA3838300";
static NSString *SECRET_KEY = @"2B1E1B53-7DE8-7E50-FF17-BC435B05EA00";
static NSString *VERSION_NUM = @"v1";

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //Backendless
    [backendless initApp:APP_ID secret:SECRET_KEY version:VERSION_NUM];
    backendless.mediaService = [MediaService new];
    
    //Parse
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"SRuWxBN23tfDRunlDEnCjAb2caWmsLcCIkd5Azui"
                  clientKey:@"a6nKLcdBvjxsC8rNITaWpq9j8PdVsC2F3h35Q2bW"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [self toggleLogin];
    return YES;
}

- (void)toggleLogin
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    PFUser *currentUser = [PFUser currentUser];
    
//    if(currentUser) {
        NSLog(@"logged in user: %@ %@", currentUser[@"firstName"], currentUser[@"lastName"]);
        DiveFeedTVC *diveFeedView = (DiveFeedTVC *)[mainStoryboard instantiateViewControllerWithIdentifier:@"DiveFeedTVC"];
        self.window.rootViewController = diveFeedView;
//    } else {
//        WelcomeVC *welcomeView = (WelcomeVC *)[mainStoryboard instantiateViewControllerWithIdentifier:@"WelcomeVC"];
//        self.window.rootViewController = welcomeView;
//    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
