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
static char kTapToDownloadGesture;
static char kKey;
static char kOptions;
static char kPlaceholderImage;
static char kCompletionBlock;
static char kFailureBlock;

@interface UIImageView (_JMImageCache)

@property (readwrite, nonatomic, strong, setter = jm_setImageURL:) NSURL *jm_imageURL;
@property (nonatomic, strong)UITapGestureRecognizer *jm_tapGestureRecognizer;

@property (nonatomic, copy)NSString *jm_key;
@property (nonatomic)JMImageCacheDownloadOptions jm_options;
@property (nonatomic, strong)UIImage *jm_placeholderImage;
@property (nonatomic, copy)void (^jm_completionBlock)(UIImage *image);
@property (nonatomic, copy)void (^jm_failureBlock)(NSURLRequest *request, NSURLResponse *response, NSError *error);

@end

@implementation UIImageView (_JMImageCache)

#pragma mark - Private Setters

- (NSURL *) jm_imageURL {
    return (NSURL *)objc_getAssociatedObject(self, &kJMImageURLObjectKey);
}
- (void) jm_setImageURL:(NSURL *)imageURL {
    objc_setAssociatedObject(self, &kJMImageURLObjectKey, imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITapGestureRecognizer *) jm_tapGestureRecognizer {
    UITapGestureRecognizer *t = (UITapGestureRecognizer *)objc_getAssociatedObject(self, &kTapToDownloadGesture);
    if (t == nil) {
        t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDownload:)];
        self.jm_tapGestureRecognizer = t;
    }
    return t;
}
- (void) setJm_tapGestureRecognizer:(UITapGestureRecognizer *)tap {
    objc_setAssociatedObject(self, &kTapToDownloadGesture, tap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)jm_key {
    return (NSString *)objc_getAssociatedObject(self, &kKey);
}
- (void)setJm_key:(NSString *)jm_key {
    objc_setAssociatedObject(self, &kKey, jm_key, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (JMImageCacheDownloadOptions)jm_options {
    return (JMImageCacheDownloadOptions)[objc_getAssociatedObject(self, &kOptions) unsignedIntegerValue];
}
- (void)setJm_options:(JMImageCacheDownloadOptions)jm_options {
    objc_setAssociatedObject(self, &kOptions, @(jm_options), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)jm_placeholderImage {
    return (UIImage *)objc_getAssociatedObject(self, &kPlaceholderImage);
}
- (void)setJm_placeholderImage:(UIImage *)jm_placeholderImage {
    objc_setAssociatedObject(self, &kPlaceholderImage, jm_placeholderImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(UIImage *))jm_completionBlock {
    return (void (^)(UIImage *))objc_getAssociatedObject(self, &kCompletionBlock);
}
- (void)setJm_completionBlock:(void (^)(UIImage *))jm_completionBlock {
    objc_setAssociatedObject(self, &kCompletionBlock, jm_completionBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(NSURLRequest *, NSURLResponse *, NSError *))jm_failureBlock {
    return (void (^)(NSURLRequest *, NSURLResponse *, NSError *))objc_getAssociatedObject(self, &kFailureBlock);
}
- (void)setJm_failureBlock:(void (^)(NSURLRequest *, NSURLResponse *, NSError *))jm_failureBlock {
    objc_setAssociatedObject(self, &kFailureBlock, jm_failureBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UIImageView (JMImageCache)


#pragma mark - Private Methods

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
    self.image = placeholderImage;

    [self setNeedsDisplay];
    [self setNeedsLayout];

    __weak UIImageView *safeSelf = self;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *i = [[JMImageCache sharedCache] cachedImageForURL:url key:key];
        if(i) {
            dispatch_async(dispatch_get_main_queue(), ^{
                safeSelf.jm_imageURL = nil;

                safeSelf.image = i;

                [safeSelf setNeedsLayout];
                [safeSelf setNeedsDisplay];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                safeSelf.image = placeholderImage;

                [safeSelf setNeedsDisplay];
                [safeSelf setNeedsLayout];
            });

            [[JMImageCache sharedCache] imageForURL:url key:key completionBlock:^(UIImage *image) {
                if ([url isEqual:safeSelf.jm_imageURL]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(image) {
                            safeSelf.image = image;
                        } else {
                            safeSelf.image = placeholderImage;
                        }

                        safeSelf.jm_imageURL = nil;

                        [safeSelf setNeedsLayout];
                        [safeSelf setNeedsDisplay];

                        if (completionBlock) completionBlock(image);
                    });
                }
            }
            failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError* error)
            {
                if (failureBlock) failureBlock(request, response, error);
            }];
        }
    });
}


- (void) setImageWithURL:(NSURL *)url key:(NSString*)key options:(JMImageCacheDownloadOptions)options placeholder:(UIImage *)placeholderImage completionBlock:(void (^)(UIImage *image))completionBlock failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failureBlock {

    // 有ClickToDownload 或 ClickToRefresh 时，才添加手势，并保留参数
    if ((options & JMImageCacheDownloadOptionsClickToDownload) != 0
        || (options & JMImageCacheDownloadOptionsClickToRefresh) != 0) {
        if (![self.gestureRecognizers containsObject:self.jm_tapGestureRecognizer]) {
            self.userInteractionEnabled = YES;
            [self addGestureRecognizer:self.jm_tapGestureRecognizer];
        }

        // 保留参数。
        self.jm_imageURL = url;
        self.jm_key = key;
        self.jm_options = options & ~JMImageCacheDownloadOptionsSearchCacheOnly; // 去除只读cache属性
        self.jm_placeholderImage = placeholderImage;
        self.jm_completionBlock = completionBlock;
        self.jm_failureBlock = failureBlock;
    }

    UIImage *i = [[JMImageCache sharedCache] imageFromDiskForURL:url key:key];

    self.image = i ? i : placeholderImage;
    if (options & JMImageCacheDownloadOptionsSearchCacheOnly) {
        return; // 结束
    }
    // 下载图片
    UIActivityIndicatorView *ai = (UIActivityIndicatorView *)[self viewWithTag:[self hash]];
    if (ai == nil) {
        ai = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGSize size = self.frame.size;
        ai.center = (CGPoint){size.width / 2, size.height / 2};
        ai.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.autoresizesSubviews = YES;
        [self addSubview:ai];
    }
    [ai startAnimating];
    [[JMImageCache sharedCache] _downloadAndWriteImageForURL:url key:key completionBlock:^(UIImage *image) {
        self.image = image;
        [ai stopAnimating];
        if (options & JMImageCacheDownloadOptionsClickToRefresh) {
            //
        } else if (options & JMImageCacheDownloadOptionsClickToDownload) {
            [self removeGestureRecognizer:self.jm_tapGestureRecognizer];
        }
        if (completionBlock) {
            completionBlock(image);
        }
    } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
        self.image = i ? i : placeholderImage;
        [ai stopAnimating];
        if (options & JMImageCacheDownloadOptionsClickToRefresh) {
            //
        } else if (options & JMImageCacheDownloadOptionsClickToDownload) {
            [self removeGestureRecognizer:self.jm_tapGestureRecognizer];
        }
        if (failureBlock) {
            failureBlock(request, response, error);
        }
    }];
}

- (void)tapToDownload:(id)sender {
    [self setImageWithURL:self.jm_imageURL
                      key:self.jm_key
                  options:self.jm_options
              placeholder:self.jm_placeholderImage
          completionBlock:self.jm_completionBlock
             failureBlock:self.jm_failureBlock];
}

@end