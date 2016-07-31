//
//  EMSocketRequest.m
//  testSocket
//
//  Created by 林峰 on 16/7/28.
//  Copyright © 2016年 yixincheng. All rights reserved.
//

#import "EMSocketRequest.h"

//exc
@interface EXCSocketPacket ()
@property(nonatomic ,strong)NSString *userName;
@property(nonatomic ,strong)NSString *servType;
@property(nonatomic ,strong)NSString *servName;
@end

@implementation EXCSocketPacket
- (NSData *)packetData{
    if (_datas) {
        return _datas;
    }
    return nil;
}

- (NSString *)packDes{
    if (_packetDesc) {
        return _packetDesc;
    }
    return @"";
}
//发送包数据
+ (EXCSocketPacket *)packetWithUserName:(NSString *)userName
                               servType:(NSString *)servType
                               servName:(NSString *)servName
                                 params:(NSArray *)params{
    EXCSocketPacket *sendSocket = [[EXCSocketPacket alloc]init];
    NSMutableString *dataString = [NSMutableString string];
    NSString *paramString = nil;
    if (params == nil|| params.count == 0) {
        paramString = @",params=?eof;";
    }else{
        paramString = [NSString stringWithFormat:@",params=%@?eof;", [params componentsJoinedByString:@"|"]];
    }
    NSString *headStr = nil;
    if (userName != nil && userName.length > 0) {
        sendSocket.userName = userName;
        headStr = [NSString stringWithFormat:
                   @"username=%@,servType=%@,servName=%@",userName,servType,servName];
    }else {
        headStr = [NSString stringWithFormat:
                   @"servType=%@,servName=%@",servType,servName];
    }
    dataString = [NSMutableString stringWithFormat:@"%@%@",headStr,paramString];
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    sendSocket.datas = [dataString dataUsingEncoding:gbkEncoding];
    sendSocket.servName = servName;
    sendSocket.servType = servType;
    sendSocket.packetDesc = dataString;
    return sendSocket;
}
@end

//exc
@interface EMSocketRequest()<GCDAsyncSocketDelegate>
@property(nonatomic, strong)NSMutableDictionary   *reciveDataDic;
@end

@implementation EMSocketRequest {
    BOOL        executing;  // 执行中
    BOOL        finished;   // 已完成
}

NSString *ipv6Add = @"";

- (void)dealloc {
    [_reciveDataDic removeAllObjects];
    [_socket disconnect];
    _socket = nil;
}

- (id)init {
    self = [super init];
    if (self) {
        executing = NO;
        finished = NO;
        
        NSError* err;
        _reciveDataDic = [NSMutableDictionary dictionary];
        
        dispatch_queue_t queue = dispatch_queue_create("exc.emobile", NULL);
        _socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:queue];
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
                    ipv6Add = [GCDAsyncSocket hostFromAddress:addrData];
                }
            }
            if (ipv6Add.length == 0) {
                ipv6Add = APP_SOCKET_HOST;
            }
        }
        [_socket connectToHost:ipv6Add onPort:APP_SOCKET_PORT error:&err];
    }
    return self;
}

//线程开始
- (void)start{
    
    if ([self isCancelled])
    {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
//    NSError* err;
//    [_socket connectToHost:ipv6Add onPort:APP_SOCKET_PORT error:&err];
//    [[NSRunLoop currentRunLoop]run];

}

- (void)main {
    NSLog(@"main begin");
    @try {
        // 必须为自定义的 operation 提供 autorelease pool，因为 operation 完成后需要销毁。
        @autoreleasepool {
//            // 提供一个变量标识，来表示需要执行的操作是否完成了，当然，没开始执行之前，为NO
//            BOOL taskIsFinished = NO;
//            // while 保证：只有当没有执行完成和没有被取消，才执行自定义的相应操作
//            while (taskIsFinished == NO && [self isCancelled] == NO){
//                // 自定义的操作
//                //sleep(10);  // 睡眠模拟耗时操作
//                NSLog(@"currentThread = %@", [NSThread currentThread]);
//                NSLog(@"mainThread    = %@", [NSThread mainThread]);
//                
//                // 这里相应的操作都已经完成，后面就是要通知KVO我们的操作完成了。
//                taskIsFinished = YES;
//            }

            NSError* err;
            [_socket connectToHost:ipv6Add onPort:APP_SOCKET_PORT error:&err];
            [[NSRunLoop currentRunLoop]run];
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception %@", e);
    }
    NSLog(@"main end");
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

-(void)cancel{
    [self.socket disconnect];
    self.socket = nil;
    [self completeOperation];
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (BOOL)connect  {
    [_reciveDataDic removeAllObjects];
    if (self.socket.isConnected) {return YES;}
    NSError *err = nil;
    NSLog(@"socket 连接: %@ : %d", ipv6Add, APP_SOCKET_PORT);
    if(![self.socket connectToHost:ipv6Add onPort:APP_SOCKET_PORT error:&err]) {
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

- (void)checkConnect{
    if (![self.socket isConnected]) {
        if (self.isConnectBlock){
            self.isConnectBlock(NO);
        }
    }
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
    [sock readDataWithTimeout:20 tag:10];
    if (self.isConnectBlock) {
        self.isConnectBlock(YES);
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err {
    [self.socket connectToHost:ipv6Add onPort:APP_SOCKET_PORT error:&err];
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkConnect) object:nil];
        [self performSelector:@selector(checkConnect) withObject:nil afterDelay:1];
    });
}

- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag {
    NSLog(@"发送数据tag- %ld",tag);
}

- (void)socket:(GCDAsyncSocket*)sock didReadData:(NSData*)data withTag:(long)tag {
    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *s = [[NSString alloc]initWithData:data encoding:gbkEncoding];
    NSLog(@"接收tag:%ld  原始数据\n  %@", tag,s);
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
                        
                        [self cancel];
                        
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
                        NSLog(@"转字典后：%@",dic);
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
            [self cancel];
        }
        
    }
    
}

-(void)requestWithSocket:(EXCSocketPacket *)socket tag:(long)tag completed:(EXCSocketBlock)completed{
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

@end