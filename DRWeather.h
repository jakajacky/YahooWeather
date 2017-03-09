//
//  DRWeather.h
//  iMeeting
//
//  Created by xqzh on 17/3/9.
//  Copyright © 2017年 Yang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Temperature : NSObject

@property NSString  *city;
@property NSString  *cityId;
@property NSString  *temperature;//temp
@property long long  publishTime;//NSString time 09:40

//@property NSString  *radar;
//@property NSString  *isRadar;
//@property NSString  *SD;
//@property NSString  *WD;
//@property NSString  *WS;
//@property NSInteger  WSE;

@end


@interface DRWeather : NSObject

@property NSString  *city;
@property NSString  *cityId;
@property NSString  *weather;
@property NSString  *img1Name;//img1//d
@property NSString  *img2Name;//img2//n
@property NSString  *maxTemperature;//temp1
@property NSString  *minTemperature;//temp2
@property long long time;//NSString ptime 09:40

@property NSString  *temperature;

- (BOOL)isTodayWeather;
- (UIImage *)image;

@end
