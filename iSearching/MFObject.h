//
//  MFObject.h
//  iSearching
//
//  Created by Mac on 2018/5/14.
//  Copyright © 2018年 MF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFObject : NSObject

/**
 断开蓝牙连接，发送通知播放声音
 */
+ (void)LocalNotificationWithMessage:(NSString *)message;

@end
