//
//  UIImageView+JMImageCache.h
//  JMImageCacheDemo
//
//  Created by Jake Marsh on 7/23/12.
//  Copyright (c) 2012 Jake Marsh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (JMImageCache)

- (void) setImageWithURL:(NSURL *)url;

- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage;

@end