//
//  ViewController.m
//  testSocket
//
//  Created by 林峰 on 16/7/13.
//  Copyright © 2016年 yixincheng. All rights reserved.
//

#import "ViewController.h"
#import "EXCSocketManager.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)requestMore:(UIButton *)sender {
//    EXCSocketPacket *packet2 = [EXCSocketPacket packetWithUserName:@"yl_001001" servType:@"mplus_user_v1" servName:@"get_myorders_stat" params:@[@"yl_001001"]];
    EXCSocketPacket *packet2 = [EXCSocketPacket packetWithUserName:@"yl_001001" servType:@"mplus_orderpool" servName:@"map_orders" params:@[@"yl_001001",@22,@113]];
    [EXCSocketManager requestWithSocket:packet2 tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@"operation1>>>get_map ");
    }];
    
    EXCSocketPacket *packet = [EXCSocketPacket packetWithUserName:@"yl_001001" servType:@"mplus_user_v1" servName:@"get_my_money" params:@[@"yl_001001"]];
    [EXCSocketManager requestWithSocket:packet tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@"operation2>>>get_my_money1");
        NSLog(@"count1 >%ld",[EXCSocketManager requestQueueCount]);
    }];

    
    [EXCSocketManager requestWithSocket:packet2 tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@"operation3>>>get_map ");
        NSLog(@"count2 >%ld",[EXCSocketManager requestQueueCount]);
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"3 sec later count >%ld",[EXCSocketManager requestQueueCount]);
    });
  
}
@end
