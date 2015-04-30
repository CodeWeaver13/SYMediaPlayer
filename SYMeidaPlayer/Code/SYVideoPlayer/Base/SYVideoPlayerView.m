//
//  SYVideoPlayerView.m
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import "SYVideoPlayerView.h"

@interface SYVideoPlayerView ()
@property (weak, nonatomic) IBOutlet UIButton *qualityBtn;
@property (weak, nonatomic) IBOutlet UIButton *lessonBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextStepBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenLockBtn;
@end

@implementation SYVideoPlayerView

- (void)awakeFromNib {
    // 标题Label样式设置
    self.titleLbl.font = [UIFont fontWithName:@"Forza-Medium" size:16.0f];
    self.titleLbl.numberOfLines = 2;
    self.titleLbl.lineBreakMode = NSLineBreakByWordWrapping;
    self.defaultTitleLabel = self.titleLbl;
    // 播放按钮
    self.playOrPauseBtn.showsTouchWhenHighlighted = YES;
    // 全屏按钮
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    // 设置视频滑动条样式
    self.videoScrubber.minimumTrackTintColor = [UIColor redColor];
    self.videoScrubber.maximumTrackTintColor = [UIColor clearColor];
    self.videoScrubber.thumbTintColor = [UIColor whiteColor];
    // 设置视频进度条样式
    self.progressView.progressTintColor = [UIColor colorWithRed:31.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:1.0];
    self.progressView.trackTintColor = [UIColor darkGrayColor];
    self.progressView.progressImage = [UIImage imageNamed:@"player_top_runtime_g_iphone"];
    // 加载指示器设置
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.autoresizingMask = UIViewAutoresizingNone;
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)self.layer setPlayer:player];
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    if (fullScreen) {
        self.topView.hidden = NO;
        self.bottomView.hidden = NO;
        self.pSliderView.hidden = NO;
        self.bottomViewDefault.hidden = YES;
    } else {
        self.topView.hidden = YES;
        self.bottomView.hidden = YES;
        self.pSliderView.hidden = YES;
        self.bottomViewDefault.hidden = NO;
    }
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
@end
