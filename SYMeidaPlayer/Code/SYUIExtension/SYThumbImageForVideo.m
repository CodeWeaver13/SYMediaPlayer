//
//  SYThumbImageForVideo.m
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/24.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import "SYThumbImageForVideo.h"
#import <AVFoundation/AVFoundation.h>

@implementation SYThumbImageForVideo

+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    AVURLAsset *asset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 1.0) actualTime:NULL error:&thumbnailImageGenerationError];
    //    if (!thumbnailImageRef)
    //        NSLog(@"error:%@", thumbnailImageGenerationError);
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    return thumbnailImage;
}


@end
