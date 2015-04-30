//
//  SYTimeFormatter.h
//  BennyEDU
//
//  Created by wangshiyu13 on 15/4/29.
//  Copyright (c) 2015年 BennyEdu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SYTimeFormatter : NSObject
/**
 将double类型的秒值转换为HH:mm:ss风格的的字符串
 
 @param seconds 传入的秒值
 
 @return 日期字符串
 */
+ (NSString *)stringFormattedTimeFromSeconds:(double *)seconds;
@end
