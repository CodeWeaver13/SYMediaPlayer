//
//  SYVideoPlayerDefaultViewController.m
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import "SYVideoPlayerDefaultViewController.h"
#import "SYVideoPlayerDefaultView.h"
#import "SYTimeFormatter.h"

@interface SYVideoPlayerDefaultViewController ()
@property (nonatomic, strong) NSDictionary *currentVideoInfo;
@property (nonatomic, strong) SYVideoPlayerDefaultView *defaultView;
@property (readwrite, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong) NSURL *currentURL;
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
@end

@implementation SYVideoPlayerDefaultViewController

{
    BOOL playWhenReady;
    BOOL scrubBuffering;
    BOOL showShareOptions;
}

#pragma mark - 初始化方法

- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming
{
    [self.videoPlayer pause];
    
    [[self.defaultView activityIndicator] startAnimating];
    // 将视频播放进度条重置为0
    [self.defaultView.progressView setProgress:0.0 animated:NO];
    [self showControls];
    
    NSString *vidID = videoID ?: @"";
    _currentVideoInfo = @{ @"title": title ?: @"", @"videoID": vidID, @"isStreaming": @(streaming), @"shareURL": shareURL ?: url};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VideoPlayerVideoChangedNotification" object:self userInfo:_currentVideoInfo];
    [self.defaultView.timeLbl setText:@"00:00/00:00"];
    self.defaultView.videoScrubber.value = 0;
    
    self.defaultView.titleLbl.text = title;
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{MPMediaItemPropertyTitle: title}];
//    [self setURL:url];
    self.URL = url;
    self.currentURL = url;
    [self changePlayBtnImage];
}

- (NSDictionary *)currentVideoInfo {
    if (_currentVideoInfo == nil) {
        _currentVideoInfo = [[NSDictionary alloc] init];
    }
    return _currentVideoInfo;
}

/** 确定defaultView所指View */
- (SYVideoPlayerDefaultView *)defaultView {
    if (!_defaultView) {
        _defaultView = (SYVideoPlayerDefaultView *)self.view;
    }
    return _defaultView;
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
        [self.defaultView.activityIndicator startAnimating];
        [self changePlayBtnImage];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"] && _videoPlayer.currentItem.playbackLikelyToKeepUp) {
        if (![self isPlaying] && (playWhenReady || self.playerIsBuffering || scrubBuffering)) {
            [self playVideo];
        }
        [self.defaultView.activityIndicator stopAnimating];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        float durationTime = CMTimeGetSeconds([[self.videoPlayer currentItem] duration]);
        float bufferTime = [self availableDuration];
        [self.defaultView.progressView setProgress:bufferTime/durationTime animated:YES];
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
        [self.defaultView setPlayer:_videoPlayer];
    } else {
        [self removeObserversFromVideoPlayerItem];
        [self.videoPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    
    [self.videoPlayer addObserver:self forKeyPath:@"externalPlaybackActive" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.videoPlayer.currentItem];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.defaultView.bottomView] || [touch.view isDescendantOfView:self.defaultView.pSliderView]) {
        return NO;
    }
    return YES;
}

#pragma mark - 通知管理
- (void)dealloc {
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
    BOOL isHidingPlayerControls = (self.defaultView.bottomView.alpha && self.defaultView.pSliderView.alpha) == 0;
    [[UIApplication sharedApplication] setStatusBarHidden:isHidingPlayerControls withAnimation:UIStatusBarAnimationNone];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - 触摸事件

/** 界面点击事件 */
- (IBAction)videoTapHandler {
    if (self.defaultView.bottomView.alpha) {
        [self hideControlsAnimated:YES];
    } else {
        [self showControls];
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
        double currentTime = floor(duration * self.defaultView.videoScrubber.value);
        
        [self.defaultView.timeLbl setText:[NSString stringWithFormat:@"%@/%@", [SYTimeFormatter stringFormattedTimeFromSeconds:&currentTime], [SYTimeFormatter stringFormattedTimeFromSeconds:&duration]]];
        
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
        [self.defaultView.activityIndicator stopAnimating];
    }
    [self changePlayBtnImage];
    [self showControls];
}

/** 进入全屏 */
- (IBAction)enterFullScreen {
    if (self.isPlaying) {
        [self playVideoClick];
    }
//    self.view.frame = [UIScreen mainScreen].bounds;
}

#pragma mark - 界面逻辑
/** 显示视频控制界面 */
- (void)showControls {
    [UIView animateWithDuration:0.4 animations:^{
        self.defaultView.bottomView.alpha = 1.0;
        self.defaultView.pSliderView.alpha = 1.0;
    } completion:nil];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlsAnimated:) object:@YES];
    
    if (self.isPlaying) {
        [self performSelector:@selector(hideControlsAnimated:) withObject:@YES afterDelay:4.0];
    }
}

/** 隐藏控制栏 */
- (void)hideControlsAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.4 animations:^{
            self.defaultView.bottomView.alpha = 0;
            self.defaultView.pSliderView.alpha = 0;
        } completion:nil];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } else {
        self.defaultView.bottomView.alpha = 0;
        self.defaultView.pSliderView.alpha = 0;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
}

/** 修改播放按钮 */
- (void)changePlayBtnImage {
    if (self.isPlaying) {
        [self.defaultView.playOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play1_iphone"] forState:UIControlStateNormal];
    } else {
        [self.defaultView.playOrPauseBtn setImage:[UIImage imageNamed:@"player_bottom_button_3_play0_iphone"] forState:UIControlStateNormal];
    }
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
        [self.defaultView.pSliderView setHidden:YES];
        [self playClock];
        return;
    }
    
    [self.defaultView.pSliderView setHidden:NO];
    
    CGFloat width = CGRectGetWidth(self.defaultView.videoScrubber.bounds);
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
        [self.defaultView.timeLbl setText:@"直播"];
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(CMTimeGetSeconds([self.videoPlayer currentTime]));
        [self.defaultView.timeLbl setText:[NSString stringWithFormat:@"%@/%@", [SYTimeFormatter stringFormattedTimeFromSeconds:&currentTime], [SYTimeFormatter stringFormattedTimeFromSeconds:&duration]]];
    }
}

/** 同步视频进度条 */
- (void)syncScrubber {
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.defaultView.videoScrubber.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.defaultView.videoScrubber minimumValue];
        float maxValue = [self.defaultView.videoScrubber maximumValue];
        double time = CMTimeGetSeconds([self.videoPlayer currentTime]);
        
        [self.defaultView.videoScrubber setValue:(maxValue - minValue) * time / duration + minValue];
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
