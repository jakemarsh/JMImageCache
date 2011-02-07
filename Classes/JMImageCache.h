//
//  JMCache.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Rubber Duck Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class JMImageCache;

@protocol JMImageCacheDelegate

@optional
- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSString *)url;

@end

@interface JMImageCache : NSCache {
	id <JMImageCacheDelegate> _imageCacheDelegate;
	
@private
	NSOperationQueue *_diskOperationQueue;
}

@property (nonatomic, assign) id <JMImageCacheDelegate> imageCacheDelegate;

- (UIImage *) imageForURL:(NSString *)url;
- (UIImage *) imageFromDiskForURL:(NSString *)url;

- (void) setImage:(UIImage *)i forURL:(NSString *)url;

- (void) writeData:(NSData*)data toPath:(NSString *)path;
- (void) performDiskWriteOperation:(NSInvocation *)invoction;

@end