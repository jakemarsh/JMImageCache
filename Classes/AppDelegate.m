//
//  JMCacheAppDelegate.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import "AppDelegate.h"
#import "JMCacheViewController.h"

@implementation AppDelegate

@synthesize window = _window;

#pragma mark -
#pragma mark NSObject

- (void) dealloc {
	[_window release];	
	[super dealloc];
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	JMCacheViewController *viewController = [[JMCacheViewController alloc] init];
	UINavigationController *mainNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

	_window.rootViewController = mainNavigationController;
	
	[viewController release];
	[mainNavigationController release];
	
	[_window makeKeyAndVisible];

	return YES;
}

@end
