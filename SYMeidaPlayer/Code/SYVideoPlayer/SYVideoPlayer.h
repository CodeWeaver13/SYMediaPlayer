//
//  SYVideoPlayer.h
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/5/11.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SYMoviePlayerManager.h"
@interface SYVideoPlayer : NSObject
+ (instancetype)player;
- (void)playWithTarget:(UIViewController *)parentVC viewRect:(CGRect)rect Title:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen;

- (void)movieWithContentOfURL:(NSURL *)urlString andViewRect:(CGRect)viewRect isAutoPlay:(BOOL)autoPlay;
@end
