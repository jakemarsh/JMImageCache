//
//  JMImageCacheOperation.h
//  JMCache
//
//  Created by Rodrigo Garcia on 7/10/13.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^JMImageCacheSuccessBlock) (UIImage *image);
typedef void (^JMImageCacheFailedBlock) (NSURLRequest *request, NSURLResponse *response, NSError* error);

@interface JMImageCacheOperation : NSOperation

@property(copy,nonatomic) JMImageCacheSuccessBlock successBlock;
@property(copy,nonatomic) JMImageCacheFailedBlock failedBlock;

-(id)initWithURL:(NSURL *)aURL aSuccessBlock:(JMImageCacheSuccessBlock)aSuccessBlock andFailedBlock:(JMImageCacheFailedBlock)aFailedBlock;

@end
