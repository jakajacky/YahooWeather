//
//  DRWeatherManager.m
//  iMeeting
//
//  Created by xqzh on 17/3/9.
//  Copyright © 2017年 Yang Yu. All rights reserved.
//

#import "DRWeatherManager.h"

#import "JSONKit.h"
#import "XMLDictionary.h"
#import "YQL.h"

#define kTemperatureUrl       @"http://www.weather.com.cn/data/sk/%@.html"//temp
#define kWeatherUrl           @"http://www.weather.com.cn/data/cityinfo/%@.html"//temp1,temp2,weather,img1,img2

#define kWeeklyWeatherUrl     @"http://m.weather.com.cn/data/%@.html"

//#define kYahooWeatherUrl       @"http://weather.yahooapis.com/forecastrss?u=c&w=%@"
#define kYahooWeatherUrl @"SELECT * FROM weather.forecast WHERE woeid=%@ AND u='c'"
@interface DRWeatherManager ()
<NSURLConnectionDelegate>

@property (nonatomic) NSOperationQueue *queue;
@property (nonatomic, strong) YQL *yql;

@end


#pragma mark -
#pragma mark Yahoo

@implementation DRWeatherManager

- (void)getYahooWeather:(void (^)(BOOL, NSArray *))completion
{
  BOOL success = NO;
  NSMutableArray *weathers = [NSMutableArray array];
  
  NSString *urlStr = [NSString stringWithFormat:kYahooWeatherUrl, _cityCode];
  // Yahoo天气API：
  NSDictionary *results = [self.yql query:urlStr];
  NSDictionary *result = [results valueForKeyPath:@"query.results"];
  
  NSDictionary *channel    = result[@"channel"];
  NSArray *yForecast       = channel[@"item"][@"forecast"];
  NSDictionary *yCondition = channel[@"item"][@"condition"];
  
  if ([yForecast isKindOfClass:[NSArray class]] && [yForecast count] > 0) {
    NSArray *weeklyWeather = [self weathersWithYahooForecast:yForecast];
    [weathers addObjectsFromArray:weeklyWeather];
  }
  
  if ([yCondition isKindOfClass:[NSDictionary class]]) {
    Weather *weather = [self weatherWithYahooCondition:yCondition];
    [weathers addObject:weather];
  }
  
  if (weathers) {
    success = YES;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    completion(success, weathers);
  });
}

- (NSArray *)weathersWithYahooForecast:(NSArray *)forecast {
  NSMutableArray *weathers = [NSMutableArray array];
  
  [forecast enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSDictionary *dict = obj;
    Weather *weather = [[Weather alloc] init];
    weather.cityId = _cityCode;
    
    NSInteger imageCode = [self weatherImageCodeWithYahooCode:dict[@"code"]];
    weather.img1Name = [NSString stringWithFormat:@"d%d.png", imageCode];
    weather.img2Name = @"";
    
    NSString *weatherType = [self weatherInfoWithYahooText:dict[@"text"]];
    if ([weatherType length] == 0) {
      weatherType = [self weatherTypeWithImageCode:imageCode];
    }
    weather.weather = weatherType;
    
    weather.temperature = @"";
    weather.maxTemperature = [NSString stringWithFormat:@"%d\u00B0C",
                              [dict[@"high"] integerValue]];
    weather.minTemperature = [NSString stringWithFormat:@"%d\u00B0C",
                              [dict[@"low"] integerValue]];
    
    NSString *dateStr = dict[@"date"];
    NSArray *dateComponents = [dateStr componentsSeparatedByString:@" "];
    NSInteger year = 0, month = 0, day = 0;
    
    NSInteger index = 0;
    for (int i = 0; i < dateComponents.count; i++) {
      if ([dateComponents[i] length] > 0) {
        NSString *component = dateComponents[i];
        
        if (index == 0) {
          day = [component integerValue];
        }
        else if (index == 1) {
          month = [NSDate monthOfString:component];
        }
        else if (index == 2) {
          year = [component integerValue];
        }
        
        index++;
      }
    }
    
    if (year && month && day) {
      NSString *dateStr = [NSString stringWithFormat:@"%4d-%02d-%02d", year, month, day];
      NSDate *date  = [dateStr dateWithFormat:NSDateFormatYearMonthDay];
      weather.time = [date millisecondsAtHour:0];
    }
    else {
      weather.time = 0;
    }
    
    [weathers addObject:weather];
  }];
  
  return weathers;
}

- (Weather *)weatherWithYahooCondition:(NSDictionary *)condition {
  Weather *weather  = [[Weather alloc] init];
  
  weather.cityId = _cityCode;
  
  NSInteger imageCode = [self weatherImageCodeWithYahooCode:condition[@"code"]];
  weather.img1Name = [NSString stringWithFormat:@"d%d.png", imageCode];
  weather.img2Name = @"";
  
  NSString *weatherType = [self weatherInfoWithYahooText:condition[@"text"]];
  if ([weatherType length] == 0) {
    weatherType = [self weatherTypeWithImageCode:imageCode];
  }
  weather.weather = weatherType;
  
  weather.temperature = [NSString stringWithFormat:@"%d\u00B0C",
                         [condition[@"temp"] integerValue]];
  weather.maxTemperature = weather.minTemperature = @"-";
  
  weather.time = [[NSDate date] millisecondsAtHour:0];
  
  return weather;
}

- (NSInteger)weatherImageCodeWithYahooCode:(NSString *)yahooCode {
  if (![yahooCode length]) {
    return NSIntegerMax;
  }
  NSDictionary *imageToYahooCode =
  @{@0 : @[@"31", @"32", @"33", @"34", @"36", @"25"],
    @1 : @[@"27", @"28", @"29", @"30", @"44"],
    @2 : @[@"26"],
    @3 : @[@"11", @"12", @"40", @"46"],
    @4 : @[@"3", @"4", @"37", @"38", @"39", @"45", @"47"],
    @5 : @[@"17", @"35"],
    @6 : @[@"5", @"6", @"7", @"18"],
    @8 : @[@"9"],
    @13 : @[@"13", @"14", @"42"],
    @15 : @[@"15", @"16"],
    @16 : @[@"41", @"43"],
    @18 : @[@"20", @"21", @"22"],
    @19 : @[@"8", @"10"],
    @20 : @[@"24"],
    @30 : @[@"19"],
    @31 : @[@"0", @"1", @"2"]};
  
  NSArray *allImageCodes = [imageToYahooCode allKeys];
  for (int i = 0; i < allImageCodes.count; i++) {
    NSNumber *imageCode = allImageCodes[i];
    NSArray *yahooCodes = imageToYahooCode[imageCode];
    if ([yahooCodes containsObject:yahooCode]) {
      return [imageCode integerValue];
    }
  }
  
  return NSIntegerMax;
}

- (NSString *)weatherInfoWithYahooText:(NSString *)yahooText {
  if ([yahooText length] == 0) {
    return nil;
  }
  NSDictionary *weatherType =
  @{@"clear" : @"晴朗", @"sunny" : @"晴", @"fair" : @"晴朗", @"cold" : @"冷", @"hot" : @"热",
    @"mostly cloudy" : @"大部多云", @"partly cloudy" : @"局部多云",
    @"cloudy" : @"阴",
    @"showers" : @"阵雨", @"scattered showers" : @"零星阵雨", @"snow showers" : @"强阵雨",
    @"severe thunderstorms" : @"强雷雨", @"thunderstorms" : @"雷雨", @"isolated thunderstorms" : @"局部地区性雷雨", @"scattered thunderstorms" : @"零星雷雨", @"thundershowers" : @"雷雨", @"isolated thundershowers" : @"局部地区性雷雨",
    @"hail" : @"冰雹", @"mixed rain and hail" : @"雨和冰雹",
    @"mixed rain and snow" : @"雨夹雪", @"mixed rain and sleet" : @"雨雪混合", @"mixed snow and sleet" : @"雨雪混合", @"sleet" : @"雨夹雪",
    @"drizzle" : @"毛毛雨",
    @"snow flurries" : @"阵雪", @"light snow showers" : @"小阵雪", @"scattered snow showers" : @"零星阵雪",
    @"blowing snow" : @"风雪", @"snow" : @"雪",
    @"heavy snow" : @"大雪",
    @"foggy" : @"雾", @"haze" : @"霾", @"smoky" : @"烟",
    @"freezing drizzle" : @"冻毛毛雨", @"freezing rain" : @"冻雨",
    @"tornado" : @"龙卷风", @"tropical storm" : @"热带风暴", @"hurricane" : @"飓风"};
  return weatherType[yahooText];
}

- (NSString *)weatherTypeWithImageCode:(NSInteger)imageCode {
  NSDictionary *weatherType =
  @{@0 : @"晴", @1 : @"多云", @2 : @"阴", @3 : @"阵雨", @4 : @"雷阵雨", @5 : @"雷阵雨伴有冰雹",
    @6 : @"雨夹雪", @7 : @"小雨", @8 : @"中雨", @9 : @"大雨", @10 : @"暴雨",
    @11 : @"大暴雨", @12 : @"特大暴雨", @13 : @"阵雪", @14 : @"小雪", @15 : @"中雪",
    @16 : @"大雪", @17 : @"暴雪", @18 : @"雾", @19 : @"冻雨", @20 : @"沙尘暴",
    @21 : @"小到中雨", @22 : @"中到大雨", @23 : @"大到暴雨", @24 : @"暴雨到大暴雨", @25 : @"大暴雨到特大暴雨",
    @26 : @"小到中雪", @27 : @"中到大雪", @28 : @"大到暴雪", @29 : @"浮尘", @30 : @"扬沙",
    @31 : @"强沙尘暴", @53 : @"霾"};
  
  return weatherType[@(imageCode)];
}

@end

