//
//  UIImageView+JMImageCache.m
//  JMImageCacheDemo
//
//  Created by Jake Marsh on 7/23/12.
//  Copyright (c) 2012 Jake Marsh. All rights reserved.
//

#import "UIImageView+JMImageCache.h"
#import "JMImageCache.h"
#import "JMImageCacheOperation.h"
#import <objc/runtime.h>

static char kJMImageURLObjectKey;
static char kJMImageRequestObjectKey;


@interface UIImageView (_JMImageCache)

@property (readwrite, nonatomic, retain, setter = jm_setImageURL:) NSURL *jm_imageURL;
@property (readwrite, nonatomic, retain, setter= jm_setOperationRequest:) JMImageCacheOperation *jm_operationRequest;

@end

@implementation UIImageView (_JMImageCache)

@dynamic jm_imageURL;
@dynamic jm_operationRequest;

@end

@implementation UIImageView (JMImageCache)

#pragma mark - Private Setters

- (NSURL *) jm_imageURL {
    return (NSURL *)objc_getAssociatedObject(self, &kJMImageURLObjectKey);
}
- (void) jm_setImageURL:(NSURL *)imageURL {
    objc_setAssociatedObject(self, &kJMImageURLObjectKey, imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JMImageCacheOperation *)jm_operationRequest
{
    return (JMImageCacheOperation *)objc_getAssociatedObject(self, &kJMImageRequestObjectKey);
}

- (void)jm_setOperationRequest:(JMImageCacheOperation *)jm_operationRequest
{
    objc_setAssociatedObject(self, &kJMImageRequestObjectKey, jm_operationRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)jm_sharedImageRequestOperationQueue
{
    static NSOperationQueue *_jm_imageRequestOperationQueue = nil;
    if(!_jm_imageRequestOperationQueue)
    {
        _jm_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_jm_imageRequestOperationQueue setMaxConcurrentOperationCount:8];
    }
    
    return _jm_imageRequestOperationQueue;
}

#pragma mark - Public Methods

- (void) setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholder:nil];
}
- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage {
    [self setImageWithURL:url key:nil placeholder:placeholderImage];
}

- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    [self setImageWithURL:url key:nil placeholder:placeholderImage];
}

- (void) setImageWithURL:(NSURL *)url placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock {
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
    
    [[self jm_operationRequest] cancel];
    self.jm_operationRequest = nil;
    
    UIImage *memoryImage;
    if (key != nil)
    {
        memoryImage = [[JMImageCache sharedCache] imageFromMemoryForKey:key];
    }
    else
    {
        memoryImage = [[JMImageCache sharedCache] imageFromMemoryForURL:url];
    }
    
    if (memoryImage != nil) {
        self.image = memoryImage;
        if (completionBlock) completionBlock(memoryImage);
        return;
    }
    
    self.jm_imageURL = url;
    self.image = placeholderImage;
    
    __weak UIImageView *safeSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *i;
        
        if (key) {
            i = [[JMImageCache sharedCache] cachedImageForKey:key];
        } else {
            i = [[JMImageCache sharedCache] cachedImageForURL:url];
        }
        
        if(i) {
            dispatch_async(dispatch_get_main_queue(), ^{
                safeSelf.jm_imageURL = nil;
                
                safeSelf.image = i;
                
                if (completionBlock) completionBlock(i);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                safeSelf.image = placeholderImage;
            });
            
            UIImage *image = [[JMImageCache sharedCache] imageFromDiskForURL:url];
            if(image)
            {
                [[JMImageCache sharedCache] setObject:image forKey:url.absoluteString];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    safeSelf.image = image;
                    if (completionBlock) completionBlock(image);
                });
            }
            else
            {
                self.jm_operationRequest = [[JMImageCacheOperation alloc] initWithURL:self.jm_imageURL aSuccessBlock:^(UIImage *image) {
                    if ([url isEqual:safeSelf.jm_imageURL]) {
                        
                        if(image != nil) [[JMImageCache sharedCache] setObject:image forKey:url.absoluteString];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(image != nil) {
                                safeSelf.image = image;
                            } else {
                                safeSelf.image = placeholderImage;
                            }
                            
                            safeSelf.jm_imageURL = nil;
                            safeSelf.jm_operationRequest = nil;
                            
                            if (completionBlock) completionBlock(image);
                        });
                    }
                } andFailedBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
                    if (failureBlock) failureBlock(request, response, error);
                }];
                
                [[self class].jm_sharedImageRequestOperationQueue addOperation:self.jm_operationRequest];
            }
        }
    });
}

@end