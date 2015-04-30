//
//  SYThumbImageForVideo.h
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/24.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SYThumbImageForVideo : NSObject
/**
 通过AVFoundation取出thumbnailImage
 */
+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;
@end
