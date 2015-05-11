//
//  SYVideoPlayer.m
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/5/11.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import "SYVideoPlayer.h"
#import "SYMoviePlayerManager.h"
#import "SYVideoPlayerViewController.h"

@interface SYVideoPlayer ()
@property (nonatomic, strong) SYVideoPlayerViewController *videoVC;
@end

@implementation SYVideoPlayer

#pragma mark - 单例模式
static id _instance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)player {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)playWithTarget:(UIViewController *)parentVC viewRect:(CGRect)rect Title:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen {
    [parentVC addChildViewController:self.videoVC];
    [parentVC.view addSubview:self.videoVC.view];
    self.videoVC.view.frame = rect;
    [self.videoVC playVideoWithTitle:title URL:url videoID:videoID shareURL:shareURL isStreaming:streaming playInFullScreen:playInFullScreen];
}

- (SYVideoPlayerViewController *)videoVC {
    if (_videoVC == nil) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SYVideoPlayerView" bundle:nil];
        _videoVC = sb.instantiateInitialViewController;
    }
    return _videoVC;
}

- (void)movieWithContentOfURL:(NSURL *)urlString andViewRect:(CGRect)viewRect isAutoPlay:(BOOL)autoPlay {
    SYMoviePlayerManager *manager = [SYMoviePlayerManager manager];
    [manager movieWithContentOfURL:urlString andViewRect:viewRect isAutoPlay:autoPlay];
}

@end
