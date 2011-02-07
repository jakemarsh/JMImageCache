//
//  JMCacheViewController.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMImageCache.h"

@interface JMCacheViewController : UITableViewController <JMImageCacheDelegate, UITableViewDelegate, UITableViewDataSource> {
	JMImageCache *_imageCache;

	NSMutableArray *_flickrImageDictionaries;
}

@end