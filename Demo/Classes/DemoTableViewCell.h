//
//  JMImageTableViewCell.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "JMImageCache.h"

@interface DemoTableViewCell : UITableViewCell <JMImageCacheDelegate>

@property (nonatomic) NSString *imageURL;

@end