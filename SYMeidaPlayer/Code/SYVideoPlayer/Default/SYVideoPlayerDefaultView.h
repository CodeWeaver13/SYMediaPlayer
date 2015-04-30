//
//  SYVideoPlayerDefaultView.h
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/28.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SYVideoPlayerDefaultView : UIView
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *pSliderView;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UILabel *timeLbl;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;

@property (nonatomic, strong) IBOutlet UISlider *videoScrubber;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (void)setPlayer:(AVPlayer *)player;
@end
