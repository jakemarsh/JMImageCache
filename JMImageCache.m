//
//  JMImageCache.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "JMImageCache.h"

static NSString *_JMImageCacheDirectory;

static inline NSString *JMImageCacheDirectory() {
	if(!_JMImageCacheDirectory) {
		_JMImageCacheDirectory = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/JMCache"] copy];
	}

	return _JMImageCacheDirectory;
}
inline static NSString *keyForURL(NSURL *url) {
	return [NSString stringWithFormat:@"JMImageCache-%u", [[url absoluteString] hash]];
}
static inline NSString *cachePathForURL(NSURL *key) {
	return [JMImageCacheDirectory() stringByAppendingPathComponent:keyForURL(key)];
}

JMImageCache *_sharedCache = nil;

@interface JMImageCache ()

@property (strong, nonatomic) NSOperationQueue *diskOperationQueue;

- (void) _downloadAndWriteImageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion;

@end

@implementation JMImageCache

@synthesize diskOperationQueue = _diskOperationQueue;

+ (JMImageCache *) sharedCache {
	if(!_sharedCache) {
		_sharedCache = [[JMImageCache alloc] init];
	}

	return _sharedCache;
}

- (id) init {
    self = [super init];
    if(!self) return nil;

    self.diskOperationQueue = [[NSOperationQueue alloc] init];

    [[NSFileManager defaultManager] createDirectoryAtPath:JMImageCacheDirectory() 
                         withIntermediateDirectories:YES 
                                       attributes:nil 
                                           error:NULL];
	return self;
}

- (void) _downloadAndWriteImageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *i = [[UIImage alloc] initWithData:data];

        NSString *cachePath = cachePathForURL(url);
        NSInvocation *writeInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(writeData:toPath:)]];
        
        [writeInvocation setTarget:self];
        [writeInvocation setSelector:@selector(writeData:toPath:)];
        [writeInvocation setArgument:&data atIndex:2];
        [writeInvocation setArgument:&cachePath atIndex:3];
        
        [self performDiskWriteOperation:writeInvocation];
        [self setImage:i forURL:url];

        dispatch_async(dispatch_get_main_queue(), ^{
            if(completion) completion(i);
        });
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
        NSString *cachePath = cachePathForURL(key);

        NSError *error = nil;

        BOOL removeSuccess = [fileMgr removeItemAtPath:cachePath error:&error];
        if (!removeSuccess) {
            //Error Occured
        }
    });
}

#pragma mark -
#pragma mark Getter Methods

- (UIImage *) cachedImageForURL:(NSURL *)url {
	if(!url) return nil;

	id returner = [super objectForKey:url];

	if(returner) {
        return returner;
	} else {
        UIImage *i = [self imageFromDiskForURL:url];
        if(i) [self setImage:i forURL:url];

        return i;
    }

    return nil;
}
- (void) imageForURL:(NSURL *)url completionBlock:(void (^)(UIImage *image))completion {
	if(!url) return;

	UIImage *i = [self cachedImageForURL:url];

	if(i) {
		if(completion) completion(i);
	} else {
        [self _downloadAndWriteImageForURL:url completionBlock:^(UIImage *image) {
            if(completion) completion(image);
        }];
    }
}
- (UIImage *) imageForURL:(NSURL *)url delegate:(id<JMImageCacheDelegate>)d {
	if(!url) return nil;
    
	UIImage *i = [self cachedImageForURL:url];

	if(i) {
		return i;
	} else {
        [self _downloadAndWriteImageForURL:url completionBlock:^(UIImage *image) {
            if(d) {
                if([d respondsToSelector:@selector(cache:didDownloadImage:forURL:)]) {
                    [d cache:self didDownloadImage:image forURL:url];
                }
            }
        }];
    }

    return nil;
}
- (UIImage *) imageFromDiskForURL:(NSURL *)url {
	UIImage *i = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:cachePathForURL(url) options:0 error:NULL]];

	return i;
}

#pragma mark -
#pragma mark Setter Methods

- (void) setImage:(UIImage *)i forURL:(NSURL *)url {
	if (i) {
		[super setObject:i forKey:url];
	}
}
- (void) removeImageForURL:(NSURL *)url {
	[super removeObjectForKey:keyForURL(url)];
}

#pragma mark -
#pragma mark Disk Writing Operations

- (void) writeData:(NSData*)data toPath:(NSString *)path {
	[data writeToFile:path atomically:YES];
}
- (void) performDiskWriteOperation:(NSInvocation *)invoction {
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithInvocation:invoction];

	[self.diskOperationQueue addOperation:operation];
}

@end