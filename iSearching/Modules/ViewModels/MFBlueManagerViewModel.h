//
//  MFBlueManagerViewModel.h
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.

/**
 1.实例化，并检查设备蓝牙状态，通过代理回调（CBCentralManager）
 2.蓝牙可用时，开始搜索周边设备，每次搜索到都会触发回调（设备：CBPeripheral）
 3.选择某个扫描到的设备进行连接，代理回调
 4.连接成功后，搜索设备包含的服务，代理回调（服务：CBService）
 5.选择某个服务，搜索服务包含的特征，代理回调（注：服务也可能包含服务）（注2：一般对特征进行订阅与读写，注意属性）（特征：CBCharacteristics）
 6.选择某个特征，搜索特征包含的描述，代理回调（描述：CBDescription）
 CBAttribute（属性）：CBService、CBCharacteristics、CBDescription
*/

#import <Foundation/Foundation.h>
#import "MFPeripheralModel.h"

typedef void (^CBPeripheralsBlock) (NSMutableArray *);

@interface MFBlueManagerViewModel : NSObject

/** 设备列表 */
@property (nonatomic,strong) NSMutableArray <MFPeripheralModel *> *modelDevices;

@property (nonatomic,copy) CBPeripheralsBlock peripheralsBlock;

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
