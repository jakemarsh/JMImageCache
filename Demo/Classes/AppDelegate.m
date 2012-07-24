//
//  JMCacheAppDelegate.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoViewController.h"

@implementation AppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	DemoViewController *viewController = [[DemoViewController alloc] init];
	UINavigationController *mainNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

	self.window.rootViewController = mainNavigationController;

	[self.window makeKeyAndVisible];

	return YES;
}

@end