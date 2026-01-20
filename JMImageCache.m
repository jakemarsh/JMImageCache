//
//  JMImageCache.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "JMImageCache.h"
#import <ImageIO/ImageIO.h>
#import "JMImageCacheOperation.h"

static inline NSString *JMImageCacheDirectory() {
	static NSString *_JMImageCacheDirectory;
	static dispatch_once_t onceToken;
    
	dispatch_once(&onceToken, ^{
		_JMImageCacheDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/JMCache"] copy];
	});
    
	return _JMImageCacheDirectory;
}
inline static NSString *keyForURL(NSURL *url) {
	return [url absoluteString];
}
static inline NSString *cachePathForKey(NSString *key) {
    NSString *fileName = [NSString stringWithFormat:@"JMImageCache-%@", [JMImageCache SHA1FromString:key]];
	return [JMImageCacheDirectory() stringByAppendingPathComponent:fileName];
}

@interface JMImageCache ()

@property (strong, nonatomic) NSOperationQueue *diskOperationQueue;
@property (strong, nonatomic) NSOperationQueue *imageOperationQueue;

- (void) _downloadAndWriteImageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failure;

@end

@implementation JMImageCache

@synthesize diskOperationQueue;
@synthesize imageOperationQueue;


+ (JMImageCache *) sharedCache {
	static JMImageCache *_sharedCache = nil;
	static dispatch_once_t onceToken;
    
	dispatch_once(&onceToken, ^{
		_sharedCache = [[JMImageCache alloc] init];
	});
    
	return _sharedCache;
}

- (id) init {
    self = [super init];
    if(!self) return nil;
    
    self.diskOperationQueue = [[NSOperationQueue alloc] init];
    self.imageOperationQueue = [[NSOperationQueue alloc] init];
    self.imageOperationQueue.maxConcurrentOperationCount = 8;
    
    [[NSFileManager defaultManager] createDirectoryAtPath:JMImageCacheDirectory()
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
	return self;
}

- (void) _downloadAndWriteImageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failure
{
    if (!key && !url) return;
    
    if (!key) {
        key = keyForURL(url);
    }
    
    JMImageCacheOperation *op = [[JMImageCacheOperation alloc] initWithURL:url aSuccessBlock:completion andFailedBlock:failure];
    [self.imageOperationQueue addOperation:op];
}

- (void) removeAllObjects {
    [super removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:JMImageCacheDirectory() error:&error];
        
        if (error == nil) {
            for (NSString *path in directoryContents) {
                NSString *fullPath = [JMImageCacheDirectory() stringByAppendingPathComponent:path];
                
                BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
                if (!removeSuccess) {
                    //Error Occured
                }
            }
        } else {
            //Error Occured
        }
    });
}
- (void) removeObjectForKey:(id)key {
    [super removeObjectForKey:key];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSString *cachePath = cachePathForKey(key);
        
        NSError *error = nil;
        
        BOOL removeSuccess = [fileMgr removeItemAtPath:cachePath error:&error];
        if (!removeSuccess) {
            //Error Occured
        }
    });
}

#pragma mark -
#pragma mark Getter Methods

- (void) imageForURL:(NSURL *)url key:(NSString *)key completionBlock:(void (^)(UIImage *image))completion failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failure{
    
	UIImage *i = [self cachedImageForKey:key];
    
	if(i) {
		if(completion) completion(i);
	} else {
        [self _downloadAndWriteImageForURL:url key:key completionBlock:completion failureBlock:failure];
    }
}

- (void) imageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion failureBlock:(void (^)(NSURLRequest *request, NSURLResponse *response, NSError* error))failure{
    [self imageForURL:url key:keyForURL(url) completionBlock:completion failureBlock:(failure)];
}

- (UIImage *)imageFromMemoryForURL:(NSURL *)url {
    return [super objectForKey:keyForURL(url)];
}

- (UIImage *) imageFromMemoryForKey:(NSString *)key {
    if(!key) return nil;
    
	return [super objectForKey:key];
}

- (UIImage *) cachedImageForKey:(NSString *)key {
    if(!key) return nil;
    
	id returner = [super objectForKey:key];
    
	if(returner) {
        return returner;
	} else {
        UIImage *i = [self imageFromDiskForKey:key];
        if(i) [self setImage:i forKey:key];
        
        return i;
    }
    
    return nil;
}

- (UIImage *) cachedImageForURL:(NSURL *)url {
    NSString *key = keyForURL(url);
    return [self cachedImageForKey:key];
}

- (UIImage *) imageForURL:(NSURL *)url key:(NSString*)key delegate:(id<JMImageCacheDelegate>)d {
	if(!url) return nil;
    
	UIImage *i = [self cachedImageForURL:url];
    
	if(i) {
		return i;
	} else {
        [self _downloadAndWriteImageForURL:url key:key completionBlock:^(UIImage *image) {
            if(d) {
                if([d respondsToSelector:@selector(cache:didDownloadImage:forURL:)]) {
                    [d cache:self didDownloadImage:image forURL:url];
                }
                if([d respondsToSelector:@selector(cache:didDownloadImage:forURL:key:)]) {
                    [d cache:self didDownloadImage:image forURL:url key:key];
                }
            }
        }
                              failureBlock:nil];
    }
    
    return nil;
}

- (UIImage *) imageForURL:(NSURL *)url delegate:(id<JMImageCacheDelegate>)d {
    return [self imageForURL:url key:keyForURL(url) delegate:d];
}

- (UIImage *) imageFromDiskForKey:(NSString *)key {
	UIImage *i = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:cachePathForKey(key) options:0 error:NULL]];
    return i;
}

- (UIImage *) imageFromDiskForURL:(NSURL *)url {
    return [self imageFromDiskForKey:keyForURL(url)];
}

#pragma mark -
#pragma mark Setter Methods

- (void) setImage:(UIImage *)i forKey:(NSString *)key {
	if (i) {
		[super setObject:i forKey:key];
	}
}
- (void) setImage:(UIImage *)i forURL:(NSURL *)url {
    [self setImage:i forKey:keyForURL(url)];
}
- (void) removeImageForKey:(NSString *)key {
	[self removeObjectForKey:key];
}
- (void) removeImageForURL:(NSURL *)url {
    [self removeImageForKey:keyForURL(url)];
}

#pragma mark -
#pragma mark Disk Writing Operations

- (void) writeData:(NSData*)data toPath:(NSString *)path {
	[data writeToFile:path atomically:YES];
    NSString *cacheName = @"memory-cache";
    
    NSDictionary *properties = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    
    NSNumber *actualCacheSize = [[NSUserDefaults standardUserDefaults] objectForKey:cacheName];
    NSNumber *fileSize = [NSNumber numberWithUnsignedLong:([properties fileSize] + actualCacheSize.longValue)];
    
    [[NSUserDefaults standardUserDefaults] setObject:fileSize  forKey:cacheName];
    
}
- (void) performDiskWriteOperation:(NSInvocation *)invoction {
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithInvocation:invoction];
    
	[self.diskOperationQueue addOperation:operation];
}

#pragma mark - Hash methods

+ (NSString *)SHA1FromString:(NSString *)string
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    
    NSData *stringBytes = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    if (CC_SHA1([stringBytes bytes], (CC_LONG)[stringBytes length], digest)) {
        
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
        
        for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
            [output appendFormat:@"%02x", digest[i]];
        }
        
        return output;
    }
    return nil;
}

@end