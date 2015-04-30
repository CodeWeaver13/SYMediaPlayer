//
//  SYMoviePlayerController.m
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/24.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import "SYMoviePlayerManager.h"
#import "SYThumbImageForVideo.h"

@implementation SYMoviePlayerManager

#pragma mark - 单例模式
static id _instance;

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (void)movieWithContentOfURL:(NSURL *)urlString andViewRect:(CGRect)viewRect isAutoPlay:(BOOL)autoPlay {
    self.view.frame = viewRect;
    /**
     movieSourceType一定要在contentURL之前！
     */
    self.movieSourceType = MPMovieSourceTypeStreaming;
    self.contentURL = urlString;
    
    [self setupThumbButtonWithURL:urlString];
    
    if (autoPlay) {
        [self play];
    } else {
        [self prepareToPlay];
    }
}

- (void)setupThumbButtonWithURL:(NSURL *)urlString {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = self.view.bounds;
    [btn setImage:[SYThumbImageForVideo thumbnailImageForVideo:urlString atTime:1.0] forState:UIControlStateNormal];
    btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    btn.backgroundColor = [UIColor blackColor];
    [btn addTarget:self action:@selector(btnclick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)btnclick:(UIButton *)btn {
    [self play];
    [btn removeFromSuperview];
}

@end
