//
//  MFBlueManagerViewModel.m
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.
//

#import "MFBlueManagerViewModel.h"

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
/** 设备列表 */
@property (nonatomic,strong) NSMutableArray <CBPeripheral *> *devices;
/** 是否主动断开连接 */
@property (nonatomic,assign) BOOL isInitiativeDisconnect;

@end

@implementation MFBlueManagerViewModel

-(id)initWithDic:(NSDictionary *)dic
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dic];
    }
    
    return self;
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    NSLog(@"undefine key ---%@",key);
}

- (void)bindViewModel:(CBPeripheralsBlock)block{
    /**
     去掉提示警告框
     */
    _manager = [[CBCentralManager alloc] initWithDelegate:self
                                                    queue:nil
                                                  options:@{CBCentralManagerOptionShowPowerAlertKey : [NSNumber numberWithBool:NO]}];
    _peripheralsBlock = block;
}

- (NSMutableArray *)devices{
    if (!_devices) {
        _devices = [[NSMutableArray alloc] init];
    }
    return _devices;
}

/**
 services 可传uuid数组，搜索指定设备
 options也可以写nil
 */
- (void)refreshBluetooth{
    [_manager scanForPeripheralsWithServices:nil
                                     options:@{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]}];
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

-(void)connect:(CBPeripheral *)peripheral{
    [_manager connectPeripheral:peripheral
                        options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                            forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

#pragma mark CBCentralManagerDelegate
//扫描设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(nonnull CBPeripheral *)peripheral advertisementData:(nonnull NSDictionary<NSString *,id> *)advertisementData RSSI:(nonnull NSNumber *)RSSI{
    MFLog(@"已发现 peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral.name, RSSI, peripheral.identifier, advertisementData);
    _peripheral = peripheral;
    // 扫描到设备之后停止扫描
    [_manager stopScan];
    
    if (![self.devices containsObject:peripheral]) {
        [[self.devices mutableArrayValueForKey:devicesKeyPath] addObject:peripheral];
    }
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
            [self refreshBluetooth];
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
        [characteristics enumerateObjectsUsingBlock:^(CBCharacteristic *character, NSUInteger idx, BOOL * _Nonnull stop) {
//            if ([[character.UUID UUIDString] isEqualToString:uuid_characteristic_receive]) {
                self.characteristic = character;
                // 拿到特征,和外围设备进行交互
                [self notifyCharacteristic:peripheral characteristic:character];
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

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    [self.manager stopScan];
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic{
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//写数据
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
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
