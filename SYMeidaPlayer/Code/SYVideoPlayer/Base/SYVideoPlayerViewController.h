//
//  SYVideoPlayerViewController.h
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SYVideoPlayerViewController : UIViewController
- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen;
@end
