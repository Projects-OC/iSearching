//
//  MFNsEnum.h
//  iSearching
//
//  Created by Mac on 2018/5/11.
//  Copyright © 2018年 MF. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,CBCentralManagerType) {
    CBCentralConnect = 0,//连接
    CBCentralDisConnect,//未连接
    CBCentralDiscover,//扫描到
    CBCentralUnDiscover//未扫描到
};
