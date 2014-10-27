//
//  UIImageView+JMImageCache.h
//  JMImageCacheDemo
//
//  Created by Jake Marsh on 7/23/12.
//  Copyright (c) 2012 Jake Marsh. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_OPTIONS(NSUInteger, JMImageCacheDownloadOptions) {
    JMImageCacheDownloadOptionsNone,
    JMImageCacheDownloadOptionsSearchCacheOnly = 1UL,
    JMImageCacheDownloadOptionsClickToDownload = 2UL,
    JMImageCacheDownloadOptionsClickToRefresh  = 4UL
};

typedef void (^JMICCompletionBlock)(UIImage *image);
typedef void (^JMICFailureBlock)(NSURLRequest *request, NSURLResponse *response, NSError *error);

@interface UIImageView (JMImageCache)

- (void) setImageWithURL:(NSURL *)url;
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage;
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *))completionBlock;
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *))completionBlock failureBlock:(JMICFailureBlock)failure;
- (void) setImageWithURL:(NSURL *)url key:(NSString*)key placeholder:(UIImage *)placeholderImage;
- (void) setImageWithURL:(NSURL *)url key:(NSString*)key placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock;
- (void) setImageWithURL:(NSURL *)url key:(NSString*)key placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock failureBlock:(JMICFailureBlock)failure;

/// key优先，无key时使用url；key无法用于从网上获取图片，仅能用于读缓存
- (void) setImageWithURL:(NSURL *)url key:(NSString*)key options:(JMImageCacheDownloadOptions)options placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock failureBlock:(JMICFailureBlock)failureBlock;

@end