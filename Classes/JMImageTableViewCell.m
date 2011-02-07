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

- (void) dealloc {
	self.imageURL = nil;

	[super dealloc];
}

@end