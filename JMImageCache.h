//
//  JMImageCache.h
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "UIImageView+JMImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@class JMImageCache;

@protocol JMImageCacheDelegate <NSObject>

@optional
- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSURL *)url;
- (void) cache:(JMImageCache *)c didDownloadImage:(UIImage *)i forURL:(NSURL *)url key:(NSString*)key;

@end

@interface JMImageCache : NSCache{
    NSURLSession *privateSession;
}

+ (JMImageCache *) sharedCache;

- (void) imageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failure;
- (void) imageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failure;

- (UIImage *) cachedImageForKey:(NSString *)key;
- (UIImage *) cachedImageForURL:(NSURL *)url;

- (UIImage *) imageForURL:(NSURL *)url key:(NSString*)key delegate:(id<JMImageCacheDelegate>)d;
- (UIImage *) imageForURL:(NSURL *)url delegate:(id<JMImageCacheDelegate>)d;

- (UIImage *) imageFromDiskForKey:(NSString *)key;
- (UIImage *) imageFromDiskForURL:(NSURL *)url;

- (void) setImage:(UIImage *)i forKey:(NSString *)key;
- (void) setImage:(UIImage *)i forURL:(NSURL *)url;
- (void) removeImageForKey:(NSString *)key;
- (void) removeImageForURL:(NSURL *)url;

- (void) writeData:(NSData *)data toPath:(NSString *)path;
- (void) performDiskWriteOperation:(NSInvocation *)invoction;

+ (NSString *)SHA1FromString:(NSString *)string;

@end
