//
//  JMImageCache.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "JMImageCache.h"

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

@end

@implementation JMImageCache

@synthesize diskOperationQueue = _diskOperationQueue;

+ (JMImageCache *) sharedCache {
	static JMImageCache *sCache = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sCache = [[JMImageCache alloc] init];
	});

	return sCache;
}

- (instancetype) init {
    self = [super init];
    if(!self) return nil;

    _diskOperationQueue = [[NSOperationQueue alloc] init];

    [[NSFileManager defaultManager] createDirectoryAtPath:JMImageCacheDirectory()
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
	return self;
}

- (void) _downloadAndWriteImageForURL:(NSURL *)url key:(NSString *)key completionBlock:(JMICCompletionBlock)completion failureBlock:(JMICFailureBlock)failure
{
    if (!key) {
        if (!url) return;
        key = keyForURL(url);
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (error) {
            if(failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(request, response, error);
                });
            }
            return;
        }
        
        UIImage *i = [[UIImage alloc] initWithData:data];
        if (!i) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:[NSString stringWithFormat:@"Failed to init image with data from for URL: %@", url] forKey:NSLocalizedDescriptionKey];
            NSError* error = [NSError errorWithDomain:@"JMImageCacheErrorDomain" code:1 userInfo:errorDetail];
            if(failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(request, response, error);
                });
            }
        } else {
            NSString *cachePath = cachePathForKey(key);
            NSInvocation *writeInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(writeData:toPath:)]];
            
            [writeInvocation setTarget:self];
            [writeInvocation setSelector:@selector(writeData:toPath:)];
            [writeInvocation setArgument:&data atIndex:2];
            [writeInvocation setArgument:&cachePath atIndex:3];
            
            [self performDiskWriteOperation:writeInvocation];
            [self setImage:i forURL:url key:key];
            
            if(completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(i);
                });
            }
        }
    });
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

- (void) removeImageForURL:(NSURL *)url key:(NSString *)key {
    if (key == nil) {
        key = keyForURL(url);
    }
    [self removeObjectForKey:key];
}

#pragma mark - Getter Methods

- (void) imageForURL:(NSURL *)url key:(NSString *)key completionBlock:(JMICCompletionBlock)completion failureBlock:(JMICFailureBlock)failure {

	UIImage *i = [self cachedImageForURL:url key:key];

	if(i) {
		if(completion) completion(i);
	} else {
        [self _downloadAndWriteImageForURL:url key:key completionBlock:completion failureBlock:failure];
    }
}

- (void) imageForURL:(NSURL *)url completionBlock:(JMICCompletionBlock)completion failureBlock:(JMICFailureBlock)failure {
    [self imageForURL:url key:keyForURL(url) completionBlock:completion failureBlock:(failure)];
}

- (UIImage *) cachedImageForURL:(NSURL *)url key:(NSString *)key {
    if (key == nil) {
        key = keyForURL(url);
    }
    if (key == nil) return nil;

    UIImage *i = [super objectForKey:key];
    if (i == nil) {
        i = [self imageFromDiskForURL:url key:key];
        [self setImage:i forURL:url key:key];
    }
    return i;
}

- (UIImage *) imageFromDiskForURL:(NSURL *)url key:(NSString *)key {
    if (key == nil) {
        key = keyForURL(url);
    }
    NSData *imgData = [NSData dataWithContentsOfFile:cachePathForKey(key) options:0 error:NULL];
    return [[UIImage alloc] initWithData:imgData];
}

#pragma mark - Setter Methods

- (void) setImage:(UIImage *)i forURL:(NSURL *)url key:(NSString *)key {
    if (key == nil) {
        key = keyForURL(url);
    }
    if (key != nil && i != nil) {
        [super setObject:i forKey:key];
    }
}

#pragma mark - Disk Writing Operations

- (void) writeData:(NSData*)data toPath:(NSString *)path {
	[data writeToFile:path atomically:YES];
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