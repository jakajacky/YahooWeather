//
//  DRWeather.m
//  iMeeting
//
//  Created by xqzh on 17/3/9.
//  Copyright © 2017年 Yang Yu. All rights reserved.
//

#import "DRWeather.h"


@implementation Temperature

@end


@implementation DRWeather

+ (NSArray *)primaryKeyList
{
  return @[@"time"];
}

- (BOOL)isTodayWeather
{
  NSDate *date = [NSDate dateWithMilliseconds:self.time];
  return [date isToday];
}

- (UIImage *)image
{
  UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", self.img1Name]];
  if (!img) {
    img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", self.img2Name]];
  }
  return img;
}

@end
