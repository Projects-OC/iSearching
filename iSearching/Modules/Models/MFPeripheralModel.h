//
//  MFPeripheralModel.h
//  iSearching
//
//  Created by Mac on 2018/5/14.
//  Copyright © 2018年 MF. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFPeripheralModel : NSObject

@property (nonatomic,strong) NSNumber *RSSI;

@property (nonatomic,copy) CBPeripheral *peripheral;

@property (nonatomic,copy) NSDictionary <NSString *,id>*advertisementData;

@end
