//
//  MFBlueManagerViewModel.h
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CBPeripheralsBlock) (NSMutableArray *);

@interface MFBlueManagerViewModel : NSObject

@property (nonatomic,copy) CBPeripheralsBlock peripheralsBlock;

-(id)initWithDic:(NSDictionary *)dic;

/**
 绑定viewModel
 */
- (void)bindViewModel:(CBPeripheralsBlock)block;

/**
 获取附近蓝牙
 */
- (void)refreshBluetooth;

/**
 连接指定的设备
 
 @param peripheral 设备信息
 */
-(void)connect:(CBPeripheral *)peripheral;

@end
