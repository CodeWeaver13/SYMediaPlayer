//
//  SYVideoPlayerView.h
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface SYVideoPlayerView : UIView 
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *pSliderView;
@property (weak, nonatomic) IBOutlet UIView *bottomViewDefault;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLbl;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;

@property (nonatomic, strong) IBOutlet UISlider *videoScrubber;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
@property (weak, nonatomic) IBOutlet UIButton *rotationBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

// 小屏属性
@property (weak, nonatomic) IBOutlet UIButton *defaultPlayOrPauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *defaultFullBtn;
@property (weak, nonatomic) IBOutlet UILabel *defaultTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *defaultVideoTime;

@property (nonatomic, assign) BOOL fullScreen;
- (void)setPlayer:(AVPlayer *)player;
@end
