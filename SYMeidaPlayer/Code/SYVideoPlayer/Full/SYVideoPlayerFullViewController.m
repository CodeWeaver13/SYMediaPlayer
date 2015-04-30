//
//  SYVideoPlayerFullViewController.m
//  SYMeidaPlayer
//
//  Created by wangshiyu13 on 15/4/30.
//  Copyright (c) 2015年 wangshiyu13. All rights reserved.
//

#import "SYVideoPlayerFullViewController.h"

@interface SYVideoPlayerFullViewController ()

@end

@implementation SYVideoPlayerFullViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    if (!self.allowPortraitFullscreen) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (!self.allowPortraitFullscreen) {
        return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    } else {
        return YES;
    }
}

@end
