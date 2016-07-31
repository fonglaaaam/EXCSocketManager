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
@interface EXCSocketManager : NSObject

+ (EXCSocketManager *)SObject;
- (void)addRequestConnction:(EMSocketRequest *)connection;
- (void)cancelRequests;
+ (void)requestWithSocket:(EXCSocketPacket *)packet tag:(long)tag completed:(EXCSocketBlock)completed;
+ (NSInteger)requestQueueCount;
@end
