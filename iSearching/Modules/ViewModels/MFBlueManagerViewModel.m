//
//  MFBlueManagerViewModel.m
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.

#import "MFBlueManagerViewModel.h"
#import "MFObject.h"

//设备名称
static NSString *peripheralName = @"";
//设备UUID
static NSString *uuid_service = @"";
//获取设备读取权限的UUID
static NSString *uuid_characteristic_receive = @"";
//获取设备写入权限的UUID
static NSString *uuid_characteristic_send = @"";

@interface MFBlueManagerViewModel()<CBCentralManagerDelegate,CBPeripheralDelegate>

/**  蓝牙对象 */
@property (nonatomic,strong) CBCentralManager *manager;
/**  蓝牙设备信息  */
@property (nonatomic,strong) CBPeripheral *peripheral;
/** 蓝牙设备读写操作服务  */
@property (nonatomic,strong) CBCharacteristic *characteristic;
/** 是否主动断开连接 */
@property (nonatomic,assign) BOOL isInitiativeDisconnect;

@end

@implementation MFBlueManagerViewModel

- (void)bindViewModel:(CBPeripheralsBlock)block{
    /**
     去掉提示警告框
     */
    _manager = [[CBCentralManager alloc] initWithDelegate:self
                                                    queue:nil
                                                  options:@{CBCentralManagerOptionShowPowerAlertKey : [NSNumber numberWithBool:NO]}];
    _peripheralsBlock = block;
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *dic = [user objectForKey:@"advertisementData"];
    NSData *data = dic[@"kCBAdvDataManufacturerData"];
    Byte *testByte = (Byte *)[data bytes];
    // Byte数组转字符串
    for (int i = 0; i < [data length]; i++) {
        NSString *str = [NSString stringWithFormat:@"%02x", testByte[i]];
        NSLog(@"byteData = %@", str);
    }
}

- (NSMutableArray *)modelDevices{
    if (!_modelDevices) {
        _modelDevices = [[NSMutableArray alloc] init];
    }
    return _modelDevices;
}

/**
 services 可传uuid数组，搜索指定设备
 options 扫描选项 常驻后台
 */
- (void)refreshBluetooth{
    [_manager scanForPeripheralsWithServices:nil
                                     options:nil/*@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}*/];
}

/**
 主动断开连接
 */
- (void)cancelPeripheralConnection{
    if (_peripheral) {
        [_manager cancelPeripheralConnection:_peripheral];
    }
    //未连接，停止搜索外设
    else{
        [_manager stopScan];
    }
}


/**
 连接选项
 CBConnectPeripheralOptionNotifyOnConnectionKey :在连接成功后，程序被挂起，给出系统提示。
 CBConnectPeripheralOptionNotifyOnDisconnectionKey :在程序挂起，蓝牙连接断开时，给出系统提示。
 CBConnectPeripheralOptionNotifyOnNotificationKey: 在程序挂起后，收到 peripheral 数据时，给出系统提示。
 */
-(void)connect:(CBPeripheral *)peripheral{
    _peripheral = peripheral;
    [_manager connectPeripheral:peripheral
                        options:@{CBConnectPeripheralOptionNotifyOnConnectionKey : @(YES),
                                 CBConnectPeripheralOptionNotifyOnDisconnectionKey : @(YES),
                                 CBConnectPeripheralOptionNotifyOnNotificationKey : @(YES)}];
}

#pragma mark CBCentralManagerDelegate
//扫描设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI{
    MFLog(@"已发现 peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral.name, RSSI, peripheral.identifier, advertisementData);
   //屏蔽不可连接
    if(![advertisementData[@"kCBAdvDataIsConnectable"] boolValue]){
        return;
    }

    if ([[advertisementData allKeys] containsObject:@"kCBAdvDataManufacturerData"]) {

    }

    _peripheral = peripheral;
//    MFPeripheralModel *model = [[MFPeripheralModel alloc] init];
//    model.peripheral = peripheral;
//    model.RSSI = RSSI;
//    model.advertisementData = advertisementData;
    if (![self.modelDevices containsObject:peripheral]) {
        [[self mutableArrayValueForKey:modelDevices] addObject:peripheral];
    }
//    [_manager stopScan];
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
    [MFObject LocalNotificationWithMessage:@"设备距离过远"];
}

//连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    MFLog(@"连接失败%@ %@",peripheral.name,error.localizedDescription);
}

//设备断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //重连
//    [_manager connectPeripheral:peripheral options:nil];
    [MFObject LocalNotificationWithMessage:@"蓝牙断开连接"];
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
            [self refreshBluetooth];
        }
            break;
        default:{
            //未知错误
        }
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *, id> *)dict{
    MFLog(@"蓝牙状态即将重置：%@ - %zd",central , dict);
    
    //dict中会传入如下键值对
    /*
     3 //恢复连接的外设数组
     4 NSString *const CBCentralManagerRestoredStatePeripheralsKey;
     5 //恢复连接的服务UUID数组
     6 NSString *const CBCentralManagerRestoredStateScanServicesKey;
     7 //恢复连接的外设扫描属性字典数组
     8 NSString *const CBCentralManagerRestoredStateScanOptionsKey;
     9 */
}


#pragma mark CBPeripheralDelegate
//已发现服务
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

//已发现特征
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
        [characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *character, NSUInteger idx, BOOL * _Nonnull stop) {
//            if ([[character.UUID UUIDString] isEqualToString:uuid_characteristic_receive]) {
            self.characteristic = character;
            
            // 这是一个枚举类型的属性
            CBCharacteristicProperties properties = character.properties;
            if (properties & CBCharacteristicPropertyBroadcast) {
                //如果是广播特性
            }
            
            if (properties & CBCharacteristicPropertyRead) {
                //如果具备读特性，即可以读取特性的value
                [peripheral readValueForCharacteristic:character];
            }
            
            if (properties & CBCharacteristicPropertyWriteWithoutResponse) {
                //如果具备写入值不需要响应的特性
                //这里保存这个可以写的特性，便于后面往这个特性中写数据
            }
            
            if (properties & CBCharacteristicPropertyWrite) {
                //如果具备写入值的特性，这个应该会有一些响应
            }
            
            if (properties & CBCharacteristicPropertyNotify) {
                //如果具备通知的特性，无响应
                [peripheral setNotifyValue:YES forCharacteristic:character];
            }
//            }
        }];
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

//读数据 常更新
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        MFLog(@"Error didUpdateNotificationStateForCharacteristic: %@", error.localizedDescription);
        return;
    }
    CBCharacteristicProperties properties = characteristic.properties;
    if (properties & CBCharacteristicPropertyRead) {
        //如果具备读特性，即可以读取特性的value
        [peripheral readValueForCharacteristic:characteristic];
    }
}

//用于检测中心向外设写数据是否成功
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"=======%@",error.userInfo);
    }
    [peripheral readValueForCharacteristic:characteristic];
}

//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic value:(NSData *)value{
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }
}

- (void)dealloc{
    
}


@end
