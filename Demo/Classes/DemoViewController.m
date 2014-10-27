//
//  JMCacheViewController.m
//  JMCache
//
//  Created by Jake Marsh on 2/7/11.
//  Copyright 2011 Jake Marsh. All rights reserved.
//

#import "DemoViewController.h"
#import "JMImageCache.h"

@interface DemoViewController ()

@property (copy, nonatomic) NSArray *modelArray;

@end

@implementation DemoViewController

static NSString *CellIdentifier = @"Cell"; // cell identifier

@synthesize modelArray = _modelArray;

- (instancetype) init {
    self = [super init];
    if(!self) return nil;

    self.title = @"The Office";

    self.modelArray = @[@{@"ImageURL" : @"http://cl.ly/4hCR/Untitled-7.png", @"Title" : @"Michael Scott"},
                        @{@"ImageURL" : @"http://cl.ly/4iIc/Untitled-7.png", @"Title" : @"Jim Halpert"},
                        @{@"ImageURL" : @"http://cl.ly/4hVv/Untitled-7.png", @"Title" : @"Pam Beasley-Halpert"},
                        @{@"ImageURL" : @"http://cl.ly/4hF3/Untitled-7.png", @"Title" : @"Dwight Schrute"},
                        @{@"ImageURL" : @"http://cl.ly/4hxj/Untitled-7.png", @"Title" : @"Andy Bernard"},
                        @{@"ImageURL" : @"http://cl.ly/4iNI/Untitled-7.png", @"Title" : @"Kevin Malone"},
                        @{@"ImageURL" : @"http://cl.ly/4iAX/Untitled-7.png", @"Title" : @"Stanley Hudson"}];

    // You should remove this next line from your apps!!!
    // It is only here for demonstration purposes, so you can get an idea for what it's like to load images "fresh" for the first time.

    [[JMImageCache sharedCache] removeAllObjects];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];

	return self;
}

#pragma mark - Autorotation Methods

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - Cleanup Methods

- (void) didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.modelArray count];
}
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    NSDictionary *cellDic = (self.modelArray)[indexPath.row];
	cell.textLabel.text = cellDic[@"Title"];

    JMImageCacheDownloadOptions option = JMImageCacheDownloadOptionsClickToDownload;
//    option |= JMImageCacheDownloadOptionsClickToRefresh;
    option |= JMImageCacheDownloadOptionsSearchCacheOnly;
    [cell.imageView setImageWithURL:[NSURL URLWithString:cellDic[@"ImageURL"]]
                                key:nil
                            options:option
                        placeholder:[UIImage imageNamed:@"placeholder"]
                    completionBlock:^(UIImage *image) {
                        //
                    } failureBlock:^(NSURLRequest *request, NSURLResponse *response, NSError *error) {
                        //
                    }];

	return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 90.0;
}
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end