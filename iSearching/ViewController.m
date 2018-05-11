//
//  ViewController.m
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.
//  https://www.jianshu.com/p/6e079da2370c

#import "MFViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

//设备名称
static NSString *peripheralName = @"";
//设备UUID
static NSString *uuid_service = @"";
//获取设备读取权限的UUID
static NSString *uuid_characteristic_receive = @"";
//获取设备写入权限的UUID
static NSString *uuid_characteristic_send = @"";

@interface MFViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

/**  蓝牙对象 */
@property (nonatomic,strong) CBCentralManager *manager;

/**  蓝牙设备信息  */
@property (nonatomic,strong) CBPeripheral *peripheral;

/** 蓝牙设备读写操作服务  */
@property (nonatomic,strong) CBCharacteristic *characteristic;

/** 是否主动断开连接 */
@property (nonatomic,assign) BOOL isInitiativeDisconnect;

@end

@implementation MFViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    /*
     services 可传uuid数组，搜索指定设备
     */
    [_manager scanForPeripheralsWithServices:nil options:nil];
}


/**
 主动断开连接
 */
- (void)cancelPeripheralConnection{
    //如果已经连接外设，断开外设
    if (_peripheral) {
        [_manager cancelPeripheralConnection:_peripheral];
    }
    //未连接，停止搜索外设
    else{
        [_manager stopScan];
    }
}


/**
 连接指定的设备

 @param peripheral 设备信息
 */
-(void)connect:(CBPeripheral *)peripheral{
    [_manager connectPeripheral:peripheral
                        options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                         forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

#pragma mark CBCentralManagerDelegate
//扫描设备，连接
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI{
    MFLog(@"已发现 peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral.name, RSSI, peripheral.identifier, advertisementData);
    if (!peripheral || !peripheral.name || ([peripheral.name isEqualToString:@""])) {
        return;
    }
    _peripheral = peripheral;
    // 扫描到设备之后停止扫描
    [_manager stopScan];
}

//连接成功，扫描services
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    if (!peripheral) {
        return;
    }
    [_manager stopScan];
    [_peripheral setDelegate:self];
    [_peripheral discoverServices:nil];
}

//获取蓝牙信号强度
-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    MFLog(@"%s,%@",__PRETTY_FUNCTION__,peripheral);
    int rssi = abs([RSSI intValue]);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@,强度:%.1ddb",_peripheral,rssi];
    MFLog(@"距离：%@", length);
}

//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    MFLog(@"%@ %@",peripheral.name,error.localizedDescription);
}

//设备断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //重连
    [_manager connectPeripheral:peripheral options:nil];
}

//获取当前蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:{
            MFLog(@"无法获取设备的蓝牙状态");
        }
            break;
        case CBCentralManagerStateResetting:{
            MFLog(@"蓝牙重置");
        }
            break;
        case CBCentralManagerStateUnsupported:{
            MFLog(@"该设备不支持蓝牙");
        }
            break;
        case CBCentralManagerStateUnauthorized:{
            MFLog(@"未获取蓝牙的权限");
        }
            break;
        case CBCentralManagerStatePoweredOff:{
            MFLog(@"蓝牙已关闭");
            /*
             UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"当前设备没有开启蓝牙权限"
             message:@""
             preferredStyle:UIAlertControllerStyleAlert];
             [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
             [alert addAction:[UIAlertAction actionWithTitle:@"开启" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
             NSURL *url = [NSURL URLWithString:@"prefs:root=Bluetooth"];
             if ([[UIApplication sharedApplication] canOpenURL:url]){
             [[UIApplication sharedApplication] openURL:url];
             }
             }]];
             */
        }
            break;
        case CBCentralManagerStatePoweredOn:{
            MFLog(@"蓝牙已打开");
            // 第一个参数填nil代表扫描所有蓝牙设备,第二个参数options也可以写nil
            [_manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]}];
        }
            break;

            
        default:{
            //未知错误
            
        }
            break;
    }
}



#pragma mark CBPeripheralDelegate
//扫描service
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error) {
        MFLog(@"didDiscoverCharacteristicsForService：%@",error);
        return;
    }
    if (peripheral != _peripheral) {
        MFLog(@"错误的peripheral");
    }
    NSArray *services = [peripheral services];
    if (!services || [services count] == 0) {
        MFLog(@"%@",services);
        return;
    }
    //连接指定设备
    [services enumerateObjectsUsingBlock:^(CBService *service, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([[service.UUID UUIDString] isEqualToString:uuid_service]) {
            [peripheral discoverCharacteristics:nil forService:service];
//            *stop = YES;
//        }
    }];
}

//发现characteristic
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error) {
        MFLog(@"didDiscoverCharacteristicsForService：%@",error);
        return;
    }
    if (peripheral != _peripheral) {
        MFLog(@"错误的peripheral");
    }
    NSArray *characteristics = [service characteristics];
    //连接指定设备
//    [characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *character, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([[character.UUID UUIDString] isEqualToString:uuid_characteristic_receive]) {
//            self.characteristic = character;
//            [self.peripheral setNotifyValue:YES forCharacteristic:character];
//        }
//    }];
}

//读数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error{
    if (error) {
        MFLog(@"Error didUpdateValueForCharacteristic: %@", error.localizedDescription);
        return;
    }
    NSData *data = characteristic.value;
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    MFLog(@"%@",string);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        MFLog(@"Error didUpdateNotificationStateForCharacteristic: %@", error.localizedDescription);
        return;
    }
    
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    } else {
        MFLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}

//写数据
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    [peripheral readValueForCharacteristic:peripheral];
}

@end
