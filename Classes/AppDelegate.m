//
//  JMCacheAppDelegate.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import "AppDelegate.h"
#import "JMCacheViewController.h"
#import "JMImageCache.h"

@implementation AppDelegate

@synthesize window;
@synthesize mainNavigationController;
@synthesize viewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	self.viewController = [[JMCacheViewController alloc] init];
	self.mainNavigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];

	[self.window addSubview:mainNavigationController.view];
	[self.window makeKeyAndVisible];

	return YES;
}

#pragma mark -
#pragma mark Memory management

- (void) dealloc {
	[viewController release];
	[mainNavigationController release];
	[window release];

	[super dealloc];
}

@end