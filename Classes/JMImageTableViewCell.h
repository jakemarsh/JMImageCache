//
//  JMImageTableViewCell.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import "JMImageCache.h"

@interface JMImageTableViewCell : UITableViewCell <JMImageCacheDelegate> {
	
	NSString *_imageURL;
}

@property (nonatomic, retain) NSString *imageURL;

@end
