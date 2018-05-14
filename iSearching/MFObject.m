//
//  MFObject.m
//  iSearching
//
//  Created by Mac on 2018/5/14.
//  Copyright © 2018年 MF. All rights reserved.
//

#import "MFObject.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

static NSString *fileName = @"alarm.wav";

@implementation MFObject

+ (void)LocalNotificationWithMessage:(NSString *)message{
    if ([UIApplication sharedApplication].applicationState==UIApplicationStateBackground) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        UILocalNotification *alarm = [[UILocalNotification alloc] init];
        alarm.alertBody = [NSString stringWithFormat:message];
        alarm.soundName = fileName;
//        alarm.alertAction = @"确定";
        [[UIApplication sharedApplication] presentLocalNotificationNow:alarm];
    }else{
        NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], fileName];
        SystemSoundID soundID;
        NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        AudioServicesPlaySystemSound(soundID);
    }
}


/**
 RSSI强度转距离
 
 @param rssi 信号📶
 @return 距离（单位M）
 */
+ (float)calcDistByRSSI:(int)rssi{
    int iRssi = abs(rssi);
    float power = (iRssi-59)/(10*2.0);
    return pow(10, power);
}

@end
