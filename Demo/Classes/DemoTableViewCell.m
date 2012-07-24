//
//  JMImageTableViewCell.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "DemoTableViewCell.h"

@implementation DemoTableViewCell

@synthesize imageURL = _imageURL;

#pragma mark -
#pragma mark JMImageCacheDelegate Methods

- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSString *)url {
	NSLog(@"didDownloadImage for URL = %@", url);

	if([url isEqualToString:self.imageURL]) {
		self.imageView.image = i;

		[self setNeedsLayout];
	}
}

@end