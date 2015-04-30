//
//  SYTimeFormatter.m
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/29.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import "SYTimeFormatter.h"

@implementation SYTimeFormatter
+ (NSString *)stringFormattedTimeFromSeconds:(double *)seconds {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:*seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    if (*seconds >= 3600) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    return [formatter stringFromDate:date];
}

@end
