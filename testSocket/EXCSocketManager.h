//
//  EXCSocketManager.h
//  testSocket
//
//  Created by 林峰 on 16/7/28.
//  Copyright © 2016年 yixincheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EMSocketRequest.h"

//typedef void(^EXCSocketBlock)(NSString *rst,NSString *rstdes,NSArray *rstinfo);
//多线程异步回调请求器 支持并发请求 一般用这个 自动断开 可是使用过程会有如下报错：
//This application is modifying the autolayout engine from a background thread, which can lead to engine corruption and weird crashes.  This will cause an exception in a future release.

@interface EXCSocketManager : NSObject

+ (EXCSocketManager *)SObject;
- (void)addRequestConnction:(EMSocketRequest *)connection;
- (void)cancelRequests;
+ (void)requestWithPacket:(EXCSocketPacket *)packet tag:(long)tag completed:(EXCSocketBlock)completed;

@end

//主线程回调请求器 一次单个请求 有缺陷 需提前连接 一直连接占用页面内存
@interface EXCSocketController : NSObject
@property(nonatomic, strong)GCDAsyncSocket *socket;
@property(nonatomic, strong)EXCSocketBlock handler;
+ (EXCSocketController *)SObject;

- (BOOL)connect;
- (void)disconnect;
- (BOOL)writeData:(EXCSocketPacket *)packet tag:(long)tag socketBlock:(EXCSocketBlock)sockBlock;
- (void)requestWithPacket:(EXCSocketPacket *)socket tag:(long)tag completed:(EXCSocketBlock)completed;
@end
