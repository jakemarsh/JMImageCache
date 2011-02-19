//
//  JMImageTableViewCell.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import "JMImageTableViewCell.h"

@implementation JMImageTableViewCell

@synthesize imageURL = _imageURL;

#pragma mark -
#pragma mark JMImageCacheDelegate Methods

- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSString *)url {
	NSLog(@"didDownloadImage for URL = %@", url);

	if([url isEqualToString:_imageURL]) {
		self.imageView.image = i;
		[self setNeedsLayout];
	}
}

- (void) dealloc {
	[_imageURL release];
	[super dealloc];
}

@end