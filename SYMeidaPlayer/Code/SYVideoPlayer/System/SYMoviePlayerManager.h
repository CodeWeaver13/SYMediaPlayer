//
//  SYMoviePlayerController.h
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/24.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SYMoviePlayerManager : MPMoviePlayerController

+ (instancetype)manager;

- (void)movieWithContentOfURL:(NSURL *)urlString andViewRect:(CGRect)viewRect isAutoPlay:(BOOL)autoPlay;

@end
