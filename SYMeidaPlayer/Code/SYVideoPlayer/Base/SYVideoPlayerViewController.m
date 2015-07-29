//
//  SYVideoPlayerViewController.m
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import "SYVideoPlayerViewController.h"
#import "SYVideoPlayerFullViewController.h"
#import "SYVideoPlayerView.h"
#import "SYTimeFormatter.h"
#import <MediaPlayer/MediaPlayer.h>

@interface SYVideoPlayerViewController ()
@property (nonatomic, strong) NSDictionary *currentVideoInfo;
@property (nonatomic, strong) SYVideoPlayerView *videoView;
@property (nonatomic, strong) SYVideoPlayerFullViewController *fullVC;
@property (nonatomic, readwrite, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong) NSURL *URL;
/** 播放时间通知监听 */
@property (nonatomic, strong) id scrubberTimeObserver;
@property (nonatomic, strong) id playClockTimeObserver;
/** 对视频播放状态的判断 */
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL seekToZeroBeforePlay;
@property (nonatomic, assign) BOOL rotationIsLocked;
@property (nonatomic, assign) BOOL playerIsBuffering;
@property (nonatomic, assign) BOOL restoreVideoPlayStateAfterScrubbing;
@property (nonatomic, assign) BOOL allowPortraitFullscreen;
// 全屏前的bounds
@property (nonatomic) CGRect previousBounds;
@end

@implementation SYVideoPlayerViewController
{
    BOOL playWhenReady;
    BOOL scrubBuffering;
    BOOL showShareOptions;
}

#pragma mark - 初始化方法
- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen {
    [self.videoPlayer pause];
    
    self.videoView.fullScreen = playInFullScreen;
    // 使屏幕不休眠
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [self.videoView.activityIndicator startAnimating];
    // 将视频播放进度条重置为0
    [self.videoView.progressView setProgress:0.0 animated:NO];
    [self showControls];
    
    NSString *vidID = videoID ?: @"";
    _currentVideoInfo = @{ @"title": title ?: @"", @"videoID": vidID, @"isStreaming": @(streaming), @"shareURL": shareURL ?: url};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VideoPlayerVideoChangedNotification" object:self userInfo:_currentVideoInfo];
    [self.videoView.timeLbl setText:@"00:00/00:00"];
    [self.videoView.defaultVideoTime setText:@"00:00/00:00"];
    self.videoView.videoScrubber.value = 0;
    
    self.videoView.titleLbl.text = title;
    self.videoView.defaultTitleLabel.text = title;
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{MPMediaItemPropertyTitle: title}];
    [self setURL:url];
    [self changePlayBtnImage];
    
    if (self.videoView.fullScreen) [self launchFullScreen];
}

- (NSDictionary *)currentVideoInfo {
    if (_currentVideoInfo == nil) {
        _currentVideoInfo = [[NSDictionary alloc] init];
    }
    return _currentVideoInfo;
}

/** 确定fullScreenView所指View */
- (SYVideoPlayerView *)videoView {
    if (!_videoView) {
        _videoView = (SYVideoPlayerView *)self.view;
    }
    return _videoView;
}

/** 在播放器数据加载完成之前初始化播放器 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object != [_videoPlayer currentItem]) {
        return;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay:
                playWhenReady = YES;
                break;
            case AVPlayerStatusFailed:
                [self removeObserversFromVideoPlayerItem];
                [self removePlayerTimeObservers];
                self.videoPlayer = nil;
                NSLog(@"failed");
                break;
            case AVPlayerStatusUnknown:
                break;
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"] && _videoPlayer.currentItem.playbackBufferEmpty) {
        self.playerIsBuffering = YES;
        [self.videoView.activityIndicator startAnimating];
        [self changePlayBtnImage];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"] && _videoPlayer.currentItem.playbackLikelyToKeepUp) {
        if (![self isPlaying] && (playWhenReady || self.playerIsBuffering || scrubBuffering)) {
            [self playVideo];
        }
        [self.videoView.activityIndicator stopAnimating];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        float durationTime = CMTimeGetSeconds([[self.videoPlayer currentItem] duration]);
        float bufferTime = [self availableDuration];
        [self.videoView.progressView setProgress:bufferTime/durationTime animated:YES];
    }
    
    return;
}

- (void)setURL:(NSURL *)URL {
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:URL];
    
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    if (!self.videoPlayer) {
        self.videoPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        self.videoPlayer.allowsExternalPlayback = YES;
        self.videoPlayer.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        [self.videoView setPlayer:_videoPlayer];
    } else {
        [self removeObserversFromVideoPlayerItem];
        [self.videoPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    
    [self.videoPlayer addObserver:self forKeyPath:@"externalPlaybackActive" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.videoPlayer.currentItem];
}

/** 解决UISilder出现手势冲突问题 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.videoView.topView] || [touch.view isDescendantOfView:self.videoView.bottomView] || [touch.view isDescendantOfView:self.videoView.pSliderView]) {
        return NO;
    }
    return YES;
}

#pragma mark - 通知管理
- (void)dealloc {
    NSLog(@"dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserversFromVideoPlayerItem];
    [self removePlayerTimeObservers];
}

- (void)removeObserversFromVideoPlayerItem {
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.videoPlayer removeObserver:self forKeyPath:@"externalPlaybackActive"];
}

/** 移除播放时间监听 */
-(void)removePlayerTimeObservers {
    if (_scrubberTimeObserver) {
        [_videoPlayer removeTimeObserver:_scrubberTimeObserver];
        _scrubberTimeObserver = nil;
    }
    
    if (_playClockTimeObserver) {
        [_videoPlayer removeTimeObserver:_playClockTimeObserver];
        _playClockTimeObserver = nil;
    }
}

#pragma mark - 控制器方法
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    BOOL isHidingPlayerControls = (self.videoView.bottomView.alpha && self.videoView.topView.alpha && self.videoView.pSliderView.alpha) == 0;
    [[UIApplication sharedApplication] setStatusBarHidden:isHidingPlayerControls withAnimation:UIStatusBarAnimationNone];
}

#pragma mark - 触摸事件
/** 界面点击事件 */
- (IBAction)videoTapHandler {
    if (self.videoView.fullScreen) {
        if (self.videoView.bottomView.alpha) {
            [self hideControlsAnimated:YES];
        } else {
            [self showControls];
        }
    } else {
        if ((self.videoView.bottomViewDefault.alpha)) {
            [self hideControlsAnimated:YES];
        } else {
            [self showControls];
        }
    }
}

/** 界面滑动事件 */
- (IBAction)videoPanGest:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:sender.view.superview];
    CGFloat x = translation.x;
    CGFloat y = translation.y;
    if ((fabs(y) / fabs(x)) > 1) {
        CGFloat currentBrightness = [UIScreen mainScreen].brightness;
        CGFloat x2 = (x * 10 / ([UIScreen mainScreen].bounds.size.width));
        [UIScreen mainScreen].brightness = fabs(currentBrightness + x2);
    } else {
        if (self.isPlaying) {
            CGFloat y2 = y * 5 / [UIScreen mainScreen].bounds.size.height;
            [self.videoView.videoScrubber setValue:(self.videoView.videoScrubber.value + y2) animated:YES];
            
            if (self.isPlaying) {
                double duration = CMTimeGetSeconds([self playerItemDuration]);
                [self changePlayBtnImage];
                [sender setTranslation:CGPointZero inView: self.videoView];
                if (sender.state == UIGestureRecognizerStateEnded) {
                    if (isfinite(duration)) {
                        double currentTime = floor(duration * self.videoView.videoScrubber.value);
                        [self.videoView.timeLbl setText:[NSString stringWithFormat:@"%@/%@", [SYTimeFormatter stringFormattedTimeFromSeconds:&currentTime], [SYTimeFormatter stringFormattedTimeFromSeconds:&duration]]];
                        
                        [self.videoPlayer seekToTime:CMTimeMakeWithSeconds((float) currentTime, NSEC_PER_SEC)];
                    }
                }
            }
        }
    }
}

/** 按下进度条按钮 */
- (IBAction)scrubbingDidBegin {
    if (self.isPlaying) {
        [self.videoPlayer pause];
        [self changePlayBtnImage];
        self.restoreVideoPlayStateAfterScrubbing = YES;
        [self showControls];
    }
}

/** 正在滑动视频进度条 */
- (IBAction)scrubberIsScrolling {
    CMTime playerDuration = [self playerItemDuration];
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(duration * self.videoView.videoScrubber.value);
        
        [self.videoView.timeLbl setText:[NSString stringWithFormat:@"%@/%@", [SYTimeFormatter stringFormattedTimeFromSeconds:&currentTime], [SYTimeFormatter stringFormattedTimeFromSeconds:&duration]]];
        
        [self.videoPlayer seekToTime:CMTimeMakeWithSeconds((float) currentTime, NSEC_PER_SEC)];
    }
}

/** 进度条滑动结束 */
- (IBAction)scrubbingDidEnd {
    if (self.restoreVideoPlayStateAfterScrubbing) {
        self.restoreVideoPlayStateAfterScrubbing = NO;
        scrubBuffering = YES;
    }
    [self showControls];
}

/** 返回到上一个控制器 */
- (IBAction)dismissToPreView {
    [self dismissViewControllerAnimated:NO completion:^{
        [self.videoPlayer pause];
        [self changePlayBtnImage];
        // 使屏幕可休眠
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        [self removeFromParentViewController];
        [self.view removeFromSuperview];
        [self removePlayerTimeObservers];
    }];
}

/** 改变清晰度 */
- (IBAction)changeQuality {
}

/** 选择课程 */
- (IBAction)selectLesson {
}

/** 分享视频 */
- (IBAction)shareVideo {
}

/** 播放或暂停视频 */
- (IBAction)playVideoClick {
    if (self.seekToZeroBeforePlay) {
        self.seekToZeroBeforePlay = NO;
        [self.videoPlayer seekToTime:kCMTimeZero];
    }
    if (self.isPlaying) {
        [self.videoPlayer pause];
    } else {
        [self playVideo];
        [self.videoView.activityIndicator stopAnimating];
    }
    [self changePlayBtnImage];
    [self showControls];
}

/** 播放下一段视频 */
- (IBAction)toNextVideo {
}

/** 锁住控制器 */
- (IBAction)lockControl {
}

/** 切换全屏 */
- (IBAction)fullScreenChange {
    [self showControls];
    if (self.videoView.fullScreen) {
        [self minimizeVideo];
    } else {
        [self launchFullScreen];
    }
}

#pragma mark - 界面逻辑
/** 显示视频控制界面 */
- (void)showControls {
    if (self.videoView.fullScreen) {
        [UIView animateWithDuration:0.4 animations:^{
            self.videoView.topView.alpha = 1.0;
            self.videoView.bottomView.alpha = 1.0;
            self.videoView.pSliderView.alpha = 1.0;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.4 animations:^{
            self.videoView.bottomViewDefault.alpha = 1.0;
        } completion:nil];
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlsAnimated:) object:@YES];
    
    if (self.isPlaying) {
        [self performSelector:@selector(hideControlsAnimated:) withObject:@YES afterDelay:4.0];
    }
}

/** 隐藏控制栏 */
- (void)hideControlsAnimated:(BOOL)animated {
    if (animated) {
        if (self.videoView.fullScreen) {
            [UIView animateWithDuration:0.4 animations:^{
                self.videoView.topView.alpha = 0;
                self.videoView.bottomView.alpha = 0;
                self.videoView.pSliderView.alpha = 0;
            } completion:nil];
        } else {
            [UIView animateWithDuration:0.4 animations:^{
                self.videoView.bottomViewDefault.alpha = 0;
            } completion:nil];
        }
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } else {
        if (self.videoView.fullScreen) {
            self.videoView.topView.alpha = 0;
            self.videoView.bottomView.alpha = 0;
            self.videoView.pSliderView.alpha = 0;
        } else {
            
            self.videoView.bottomViewDefault.alpha = 0;
        }
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
}

/** 修改播放按钮 */
- (void)changePlayBtnImage {
    if (self.isPlaying) {
        [self.videoView.playOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play1_iphone"] forState:UIControlStateNormal];
        [self.videoView.defaultPlayOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play1_iphone"] forState:UIControlStateNormal];
    } else {
        [self.videoView.playOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play0_iphone"] forState:UIControlStateNormal];
        [self.videoView.defaultPlayOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play0_iphone"] forState:UIControlStateNormal];
    }
}

- (void)launchFullScreen {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
    
    [self hideControlsAnimated:YES];
    
    if (!self.fullVC) {
        self.fullVC = [[SYVideoPlayerFullViewController alloc] init];
        self.fullVC.allowPortraitFullscreen = self.allowPortraitFullscreen;
    }
    self.videoView.fullScreen = YES;
    self.previousBounds = self.videoView.frame;
    [self.videoView removeFromSuperview];
    [self.fullVC.view addSubview:self.videoView];
    
    [UIView animateWithDuration:0.35 animations:^{
        self.videoView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    }];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.fullVC animated:YES completion:nil];
}


/** 缩小视频 */
- (void)minimizeVideo {
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:NO completion:^{
        [self showControls];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        self.videoView.fullScreen = NO;
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        [UIView animateWithDuration:0.35 animations:^{
            [self hideControlsAnimated:YES];
            self.videoView.frame = self.previousBounds;
            [self.parentViewController.view addSubview:self.view];
        }];
    }];
}

/** 旋转界面 */
- (void)forceOrientationChange {
    _rotationIsLocked = YES;
    [self performSelector:@selector(unlockRotationLock) withObject:nil afterDelay:0.5];
}

- (void)unlockRotationLock {
    _rotationIsLocked = NO;
}

#pragma mark - 视频播放逻辑
/** 判断是否在播放 */
- (BOOL)isPlaying {
    return [self.videoPlayer rate] != 0.0;
}

/** 当视频播放完的结束动作 */
- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self changePlayBtnImage];
    [self minimizeVideo];
}

/** 获取影片时间 */
- (CMTime)playerItemDuration {
    if (_videoPlayer.status == AVPlayerItemStatusReadyToPlay) {
        return([_videoPlayer.currentItem duration]);
    }
    return(kCMTimeInvalid);
}

/** 播放视频 */
- (void)playVideo {
    if (self.view.superview) {
        self.playerIsBuffering = NO;
        scrubBuffering = NO;
        playWhenReady = NO;
        
        [self.videoPlayer play];
        [self updatePlaybackProgress];
    }
}

/** 更新视频进度条 */
- (void)updatePlaybackProgress {
    [self changePlayBtnImage];
    [self showControls];
    
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (CMTIME_IS_INDEFINITE(playerDuration) || duration <= 0) {
        [self.videoView.pSliderView setHidden:YES];
        [self playClock];
        return;
    }
    
//    [self.videoView.pSliderView setHidden:NO];
    
    CGFloat width = CGRectGetWidth([self.videoView.videoScrubber bounds]);
    interval = 0.5f * duration / width;
    __weak id weakSelf = self;
    _scrubberTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncScrubber];
    }];
    
    // 每秒更新播放时间
    _playClockTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf playClock];
    }];
}

/** 播放时间 */
- (void)playClock {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    if (CMTIME_IS_INDEFINITE(playerDuration)) {
        [self.videoView.timeLbl setText:@"直播"];
        [self.videoView.defaultVideoTime setText:@"直播"];
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(CMTimeGetSeconds([self.videoPlayer currentTime]));
        NSString *text = [NSString stringWithFormat:@"%@/%@", [SYTimeFormatter stringFormattedTimeFromSeconds:&currentTime], [SYTimeFormatter stringFormattedTimeFromSeconds:&duration]];
        [self.videoView.timeLbl setText:text];
        [self.videoView.defaultVideoTime setText:text];
    }
}

/** 同步视频进度条 */
- (void)syncScrubber {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.videoView.videoScrubber.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.videoView.videoScrubber minimumValue];
        float maxValue = [self.videoView.videoScrubber maximumValue];
        double time = CMTimeGetSeconds([self.videoPlayer currentTime]);
        
        [self.videoView.videoScrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

/** 获取播放时长 */
- (float)availableDuration {
    NSArray *loadedTimeRanges = [[self.videoPlayer currentItem] loadedTimeRanges];
    
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}
@end
