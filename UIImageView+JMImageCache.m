//
//  UIImageView+JMImageCache.m
//  JMImageCacheDemo
//
//  Created by Jake Marsh on 7/23/12.
//  Copyright (c) 2012 Jake Marsh. All rights reserved.
//

#import "UIImageView+JMImageCache.h"
#import "JMImageCache.h"
#import <objc/runtime.h>

static char kJMImageURLObjectKey;

@interface UIImageView (_JMImageCache)

@property (readwrite, nonatomic, retain, setter = jm_setImageURL:) NSURL *jm_imageURL;

@end

@implementation UIImageView (_JMImageCache)

@dynamic jm_imageURL;

@end

@implementation UIImageView (JMImageCache)

#pragma mark - Private Setters

- (NSURL *) jm_imageURL {
    return (NSURL *)objc_getAssociatedObject(self, &kJMImageURLObjectKey);
}
- (void) jm_setImageURL:(NSURL *)imageURL {
    objc_setAssociatedObject(self, &kJMImageURLObjectKey, imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Public Methods

- (void) setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholder:nil];
}
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage {
    [self setImageWithURL:url key:nil placeholder:placeholderImage];
}
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *))completionBlock {
    [self setImageWithURL:url key:nil placeholder:placeholderImage completionBlock:completionBlock failureBlock:nil];
}
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *))completionBlock failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failureBlock {
    [self setImageWithURL:url key:nil placeholder:placeholderImage completionBlock:completionBlock failureBlock:failureBlock];
}
- (void) setImageWithURL:(NSURL *)url key:(NSString*)key placeholder:(UIImage *)placeholderImage {
    [self setImageWithURL:url key:key placeholder:placeholderImage completionBlock:nil];
}
- (void) setImageWithURL:(NSURL *)url key:(NSString*)key placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock {
    [self setImageWithURL:url key:key placeholder:placeholderImage completionBlock:completionBlock failureBlock:nil];
}

- (void) setImageWithURL:(NSURL *)url key:(NSString*)key placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failureBlock{
    self.jm_imageURL = url;
    [self assignImage:placeholderImage refreshSafeSelf:self];
    
    __unsafe_unretained UIImageView *safeSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[JMImageCache sharedCache] imageForURL:url key:key completionBlock:^(UIImage *image) {
            if ([url isEqual:safeSelf.jm_imageURL]) {
                
                if (image) {
                    [self assignImage:image onMainQueueWithSafeSelf:safeSelf];
                } else {
                    [self assignImage:placeholderImage onMainQueueWithSafeSelf:safeSelf];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    safeSelf.jm_imageURL = nil;
                    
                    if (completionBlock) completionBlock(image);
                });
            }
        }
                                   failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError* error)
         {
             if (failureBlock) failureBlock(request, response, error);
         }];
        
    });
}

- (void)assignImage:(UIImage *)cachedImage onMainQueueWithSafeSelf:(__unsafe_unretained UIImageView *)safeSelf{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self assignImage:cachedImage refreshSafeSelf:safeSelf];
    });
}

- (UIImage *)getImageFromSharedCacheWith:(NSURL *)url key:(NSString *)key {
    UIImage *cachedImage;
    if (key) {
        cachedImage = [[JMImageCache sharedCache] cachedImageForKey:key];
    } else {
        cachedImage = [[JMImageCache sharedCache] cachedImageForURL:url];
    }
    return cachedImage;
}

- (void) assignImage:(UIImage *)cachedImage refreshSafeSelf:(__unsafe_unretained UIImageView *)safeSelf {
    safeSelf.image = cachedImage;
    
    [safeSelf setNeedsLayout];
    [safeSelf setNeedsDisplay];
}

@end