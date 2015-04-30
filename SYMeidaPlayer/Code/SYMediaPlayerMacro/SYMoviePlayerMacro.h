//
//  SYMoivePlayerMacro.h
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/24.
//  Copyright (c) 2015年 陆枫. All rights reserved.
//

#ifndef BennyEDU_SYMoivePlayerMacro_h
#define BennyEDU_SYMoivePlayerMacro_h

#define SY_MOVIE_FINISHEDCALLBACK \
- (void)movieFinishedCallback:(NSNotification*)notify { \
SYMoviePlayerManager *movie = [notify object]; \
[[NSNotificationCenter defaultCenter] removeObserver:self name: MPMoviePlayerPlaybackDidFinishNotification object:movie]; \
[movie.view removeFromSuperview]; \
}

#endif