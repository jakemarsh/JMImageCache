//
//  JMCacheAppDelegate.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JMCacheViewController, JMImageCache;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	JMCacheViewController *viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) JMCacheViewController *viewController;

@end