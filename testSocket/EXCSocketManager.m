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



//exc
@interface EXCSocketController()<GCDAsyncSocketDelegate>
@property(nonatomic, strong)NSMutableDictionary   *reciveDataDic;
@end

@implementation EXCSocketController
- (void)dealloc {
    [_reciveDataDic removeAllObjects];
    [_socket disconnect];
    _socket = nil;
}

static NSString *ipv6 = @"";

+ (EXCSocketManager *)SObject {
    static id __AppStaticManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __AppStaticManager = [[[self class] alloc] init];
    });
    return __AppStaticManager;
}

- (id)init {
    self = [super init];
    if (self) {
        NSError* err;
        _reciveDataDic = [NSMutableDictionary dictionary];
        
        //        dispatch_queue_t queue = dispatch_queue_create("exc.emobile", NULL);
        _socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        //适配ipv6
        {
            NSError *addresseError = nil;
            NSArray *addresseArray = [GCDAsyncSocket lookupHost:APP_SOCKET_HOST
                                                           port:APP_SOCKET_PORT
                                                          error:&addresseError];
            if (addresseError) {
                NSLog(@"");
            }
            
            for (NSData *addrData in addresseArray) {
                if ([GCDAsyncSocket isIPv6Address:addrData]) {
                    ipv6 = [GCDAsyncSocket hostFromAddress:addrData];
                }
            }
            
            if (ipv6.length == 0) {
                ipv6 = APP_SOCKET_HOST;
            }
        }
        [_socket connectToHost:ipv6 onPort:APP_SOCKET_PORT error:&err];
    }
    return self;
}

- (BOOL)connect  {
    [_reciveDataDic removeAllObjects];
    if (self.socket.isConnected) {return YES;}
    NSError *err = nil;
    NSLog(@"socket 连接: %@ : %d", ipv6, APP_SOCKET_PORT);
    if(![self.socket connectToHost:ipv6 onPort:APP_SOCKET_PORT error:&err]) {
        NSLog(@"Cant't Open Port. err:%@", err);
        return NO;
    }
    return YES;
}

- (void)disconnect{
    [_reciveDataDic removeAllObjects];
    [_socket disconnect];
}

- (void)reconnect {
    if (_socket) {
        [self disconnect];
        [self connect];
    }
}

- (NSString *)getProperIPWithAddress:(NSString *)ipAddr port:(UInt32)port
{
    NSError *addresseError = nil;
    NSArray *addresseArray = [GCDAsyncSocket lookupHost:ipAddr
                                                   port:port
                                                  error:&addresseError];
    if (addresseError) {
        NSLog(@"");
    }
    
    NSString *ipv6Addr = @"";
    for (NSData *addrData in addresseArray) {
        if ([GCDAsyncSocket isIPv6Address:addrData]) {
            ipv6Addr = [GCDAsyncSocket hostFromAddress:addrData];
        }
    }
    if (ipv6Addr.length == 0) {
        ipv6Addr = ipAddr;
    }
    return ipv6Addr;
}

- (BOOL)writeData:(EXCSocketPacket *)packet tag:(long)tag socketBlock:(EXCSocketBlock)sockBlock{
    NSData *packetData = [packet packetData];
    NSMutableData *reciveData = [NSMutableData data];
    reciveData.length = 0;
    [_reciveDataDic setValue:reciveData forKey:[NSString stringWithFormat:@"%ld",tag]];
    self.handler = sockBlock;
    [self.socket writeData:packetData withTimeout:-1 tag:tag];
    NSLog(@"网络请求》》 \n%@",packet.packetDesc);
    return YES;
}

- (void)socket:(GCDAsyncSocket*)sock didConnectToHost:(NSString*)host port:(uint16_t)port {
    NSLog(@"连接成功-%@",[self class]);
    [sock readDataWithTimeout:20 tag:10];
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err {
    //        [self.socket connectToHost:ipv6 onPort:APP_SOCKET_PORT error:&err];
    //    if ([Reachability isExistenceNetwork] && err.code != 100) {
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reconnect) object:nil];
    //            [self performSelector:@selector(reconnect) withObject:nil afterDelay:5];
    //        });
    //    }
}

- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag {
    NSLog(@"发送数据tag- %ld",tag);
}

- (void)socket:(GCDAsyncSocket*)sock didReadData:(NSData*)data withTag:(long)tag {
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *s = [[NSString alloc]initWithData:data encoding:gbkEncoding];
    NSLog(@"接收tag:%ld  数据  %@", tag,s);
    //按tag接收data
    NSMutableData *reciveData = (NSMutableData *)[_reciveDataDic valueForKey:[NSString stringWithFormat:@"%ld",tag]];
    if (reciveData == nil) {
        reciveData = [NSMutableData dataWithLength:0];
    }
    NSRange eofRange = [s rangeOfString:@"?eof;" options:NSLiteralSearch];
    if (eofRange.location == NSNotFound) {//还没?eof;
        [reciveData appendData:data];
        [_reciveDataDic setValue:reciveData forKey:[NSString stringWithFormat:@"%ld",tag]];
        [sock readDataWithTimeout:-1 tag:tag];//持续接收服务端放回的数据
    }else{
        if (reciveData.length == 0) {
            [reciveData setData:data];
        }
        else //(reciveData.length>0)
        {
            if (![s isEqualToString:@"?eof;"]) {
                [reciveData appendData:data];
            }
        }
        NSString *str = [[NSString alloc]initWithData:reciveData encoding:gbkEncoding];
        NSArray *array = [str componentsSeparatedByString:@","];
        NSString *testStr = array.firstObject;
        NSRange range = [testStr rangeOfString:@"=" options:NSLiteralSearch];
        if (range.location != NSNotFound) {
            NSString *value = [testStr substringFromIndex:range.location + 1];//从index开始，到字符串结束
            if([value isEqualToString:@"OK"]){
                NSString *rstDes = array[1];
                rstDes = (NSString *)[rstDes componentsSeparatedByString:@"="].lastObject;
                NSString *info = array.lastObject;
                NSArray *rstinfoArray = [info componentsSeparatedByString:@"="];
                NSString *rstinfo = rstinfoArray.lastObject;
                NSArray *rstinfoRealArray = [rstinfo componentsSeparatedByString:@"\r\n"];
                
                NSString *key = rstinfoRealArray[1];
                NSArray *keyArray = [key componentsSeparatedByString:@"|"];
                
                NSMutableArray *rstinfoRealArray2 = [NSMutableArray arrayWithArray:rstinfoRealArray];
                [rstinfoRealArray2 removeLastObject];
                NSMutableArray *handlerArray = [NSMutableArray array];
                if (rstinfoRealArray2.count<=2) {
                    if(self.handler){
                        self.handler(@"OK",@"无效数据",@[]);
                        //清除缓存data
                        [_reciveDataDic removeObjectForKey:[NSString stringWithFormat:@"%ld",tag]];
                        [self disconnect];
                        return;
                    }
                }
                [rstinfoRealArray2 enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
                    if (idx>=2) {
                        NSString *value = obj;
                        NSArray *vArray = [value componentsSeparatedByString:@"|"];
                        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                        [keyArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
                            if([vArray objectAtIndex:idx]!=nil){
                                NSString *valueStr = vArray[idx];
                                if ([valueStr isEqualToString:@"null"]||[valueStr isEqualToString:@""]) {
                                    valueStr = @"";
                                }
                                [dic setValue:valueStr forKey:key];
                            }
                        }];
                        NSLog(@"%@",dic);
                        [handlerArray addObject:dic];
                    }
                }];
                if(self.handler != nil){
                    self.handler(@"OK",rstDes,handlerArray);
                }
            }else{//Fail
                NSString *rstDes = array.lastObject;
                NSArray *rstArray = [rstDes componentsSeparatedByString:@"="];
                NSLog(@"%@",rstArray.lastObject);
                NSString *rstdes = rstArray.lastObject;
                if(self.handler){
                    self.handler(@"FAIL",rstdes,@[]);
                }
            }
            //清除缓存data
            [_reciveDataDic removeObjectForKey:[NSString stringWithFormat:@"%ld",tag]];
        }
        
    }
    
}

-(void)requestWithPacket:(EXCSocketPacket *)socket tag:(long)tag completed:(EXCSocketBlock)completed{
    if ([self connect]) {
        [self writeData:socket tag:tag socketBlock:^(NSString *rst, NSString *rstdes,NSArray *rstinfo) {
            if (completed) {
                completed(rst,rstdes,rstinfo);
            }
        }];
    }else{
        if (completed) {
            completed(@"Fail",@"Socket连接未建立",@[]);
        }
    }
}
@end
