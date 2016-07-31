//
//  EXCSocketManager.m
//  testSocket
//
//  Created by 林峰 on 16/7/28.
//  Copyright © 2016年 yixincheng. All rights reserved.
//

#import "EXCSocketManager.h"
#import "EXCSocketRequestQueue.h"

@interface EXCSocketManager()
@property(nonatomic, strong)EXCSocketRequestQueue *requestQueue;
@end

@implementation EXCSocketManager
+ (EXCSocketManager *)SObject {
    static id __AppStaticManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __AppStaticManager = [[[self class] alloc] init];
    });
    return __AppStaticManager;
}

- (void)addRequestConnction:(EMSocketRequest *)connection {
    if (connection) {
        [_requestQueue addOperation:connection];
        NSLog(@"%@",self.requestQueue.operations);
    }
}

- (void)cancelRequests{
    [self.requestQueue cancelAllOperations];
}

+ (NSInteger)requestQueueCount{
    EXCSocketManager *manager = [EXCSocketManager SObject];
    return  manager.requestQueue.operationCount;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestQueue = [[EXCSocketRequestQueue alloc]init];
        _requestQueue.maxConcurrentOperationCount = 5;
    }
    return self;
}

+ (void)requestWithSocket:(EXCSocketPacket *)packet tag:(long)tag completed:(EXCSocketBlock)completed{
    EXCSocketManager *manager = [EXCSocketManager SObject];
    
    EMSocketRequest *conn = [[EMSocketRequest alloc]init];
    conn.data = packet;
    __weak typeof(conn) socketOperation = conn;    
    conn.isConnectBlock = ^(BOOL isConnect){
        if (isConnect) {
            [socketOperation requestWithSocket:packet tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
                if (completed) {
                    completed(rst,rstdes,rstinfo);
                    [socketOperation cancel];
                }
            }];
        }else{
            completed(@"FAIL",@"socket disconnect",@[]);
        }
    };
    [manager addRequestConnction:conn];
}

@end

