//
//  SYVideoPlayerView.m
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import "SYVideoPlayerView.h"
#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
#define PLAYER_CONTROL_BAR_HEIGHT 42

@interface SYVideoPlayerView ()
@property (strong, nonatomic) UIButton *qualityBtn;
@property (strong, nonatomic) UIButton *lessonBtn;
@property (strong, nonatomic) UIButton *nextStepBtn;
@property (strong, nonatomic) UIButton *screenLockBtn;
@end

@implementation SYVideoPlayerView

- (void)awakeFromNib {
    // bottomView
    self.bottomView = [[UIView alloc] init];
    self.bottomView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    [self addSubview:self.bottomView];
    // pSliderView
    self.pSliderView = [[UIView alloc] init];
    self.pSliderView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.pSliderView];
    // 标题Label样式设置
    self.titleLbl = [[UILabel alloc] init];
    self.titleLbl.font = [UIFont fontWithName:@"Forza-Medium" size:16.0f];
    self.titleLbl.numberOfLines = 2;
    self.titleLbl.lineBreakMode = NSLineBreakByWordWrapping;
    [self.bottomView addSubview:self.titleLbl];
    // timeLbl
    self.timeLbl = [[UILabel alloc] init];
    self.timeLbl.backgroundColor = [UIColor clearColor];
    self.timeLbl.textColor = [UIColor whiteColor];
    [self.timeLbl setFont:[UIFont fontWithName:@"DINRoundCompPro" size:14.0f]];
    [self.timeLbl setTextAlignment:NSTextAlignmentCenter];
    [self.bottomView addSubview:self.timeLbl];
    // playOrPauseBtn
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play0_iphone"] forState:UIControlStateNormal];
    self.playOrPauseBtn.showsTouchWhenHighlighted = YES;
    [self.playOrPauseBtn setNeedsDisplay];
    [self.bottomView addSubview:self.playOrPauseBtn];
    // 全屏按钮
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"player_top_button_resize"] forState:UIControlStateNormal];
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.bottomView addSubview:self.fullScreenBtn];
    // 设置视频滑动条样式
    self.videoScrubber = [[UISlider alloc] init];
    self.videoScrubber.minimumTrackTintColor = [UIColor redColor];
    self.videoScrubber.maximumTrackTintColor = [UIColor clearColor];
    self.videoScrubber.thumbTintColor = [UIColor whiteColor];
    [self.bottomView addSubview:self.videoScrubber];
    // 设置视频进度条样式
    self.progressView = [[UIProgressView alloc] init];
    self.progressView.progressTintColor = [UIColor colorWithRed:31.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:1.0];
    self.progressView.trackTintColor = [UIColor darkGrayColor];
    self.progressView.progressImage = [UIImage imageNamed:@"player_top_runtime_g_iphone"];
    [self.bottomView addSubview:self.progressView];
    // 加载指示器设置
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:self.activityIndicator];
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = [self bounds];
    self.autoresizingMask = UIViewAutoresizingNone;
    // bottomView
    self.bottomView.frame = CGRectMake(bounds.origin.x, bounds.size.height - PLAYER_CONTROL_BAR_HEIGHT, bounds.size.width, PLAYER_CONTROL_BAR_HEIGHT);
    // pSliderView
    self.pSliderView.frame = CGRectMake(-2, bounds.size.height - self.bottomView.frame.size.height - 15, bounds.size.width + 4, 31);
    // activity
    self.activityIndicator.frame = CGRectMake((bounds.size.width - self.activityIndicator.frame.size.width)/2.0, (bounds.size.height - self.activityIndicator.frame.size.width)/2.0, self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)self.layer setPlayer:player];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
@end
