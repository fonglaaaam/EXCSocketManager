//
//  EMSocketRequest
//  testSocket
//
//  Created by 林峰 on 16/7/28.
//  Copyright © 2016年 yixincheng. All rights reserved.
//

#define APP_SOCKET_HOST             @"192.168.1.35"
#define APP_SOCKET_PORT             9011

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

typedef void(^EXCSocketBlock)(NSString *rst,NSString *rstdes,NSArray *rstinfo);
typedef void(^EXCisConnectBlock)(BOOL isConnect);

@interface EXCSocketPacket : NSObject
@property(nonatomic, strong)NSData          *datas;
@property(nonatomic, strong)NSString        *packetDesc;
- (NSData *)packetData;
//发送包数据封装
+ (EXCSocketPacket *)packetWithUserName:(NSString *)userName
                               servType:(NSString *)servType
                               servName:(NSString *)servName
                                 params:(NSArray *)params;
@end

@interface EMSocketRequest : NSOperation
@property(nonatomic, strong)GCDAsyncSocket *socket;
@property(nonatomic, strong)EXCSocketBlock handler;
@property(nonatomic, strong)EXCisConnectBlock isConnectBlock;
@property(nonatomic, strong)EXCSocketPacket *data;
@property(nonatomic, assign)BOOL           isConnect;

- (BOOL)connect;
- (void)disconnect;
- (BOOL)writeData:(EXCSocketPacket *)packet tag:(long)tag socketBlock:(EXCSocketBlock)sockBlock;
- (void)requestWithSocket:(EXCSocketPacket *)socket tag:(long)tag completed:(EXCSocketBlock)completed;
@end