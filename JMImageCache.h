//
//  JMImageCache.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "UIImageView+JMImageCache.h"

@interface JMImageCache : NSCache

+ (JMImageCache *) sharedCache;

- (void) imageForURL:(NSURL *)url key:(NSString *)key completionBlock:(JMICCompletionBlock)completion failureBlock:(JMICFailureBlock)failure;
- (void) imageForURL:(NSURL *)url completionBlock:(JMICCompletionBlock)completion failureBlock:(JMICFailureBlock)failure;

- (UIImage *) cachedImageForURL:(NSURL *)url key:(NSString *)key;;

- (UIImage *) imageFromDiskForURL:(NSURL *)url key:(NSString *)key;;

- (void) setImage:(UIImage *)i forURL:(NSURL *)url key:(NSString *)key;
- (void) removeImageForURL:(NSURL *)url key:(NSString *)key;

- (void) writeData:(NSData *)data toPath:(NSString *)path;
- (void) performDiskWriteOperation:(NSInvocation *)invoction;

- (void) _downloadAndWriteImageForURL:(NSURL *)url key:(NSString *)key completionBlock:(JMICCompletionBlock)completion failureBlock:(JMICFailureBlock)failure;

@end
