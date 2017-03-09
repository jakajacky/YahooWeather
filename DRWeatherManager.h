//
//  DRWeatherManager.h
//  iMeeting
//
//  Created by xqzh on 17/3/9.
//  Copyright © 2017年 Yang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DRWeather.h"

@interface DRWeatherManager : NSObject
@property (nonatomic) NSString *cityCode;
- (void)getYahooWeather:(void (^)(BOOL success, NSArray *weathers))completion;

@end
