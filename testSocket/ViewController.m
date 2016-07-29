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
    EXCSocketPacket *packet2 = [EXCSocketPacket packetWithUserName:@"yl_001001" servType:@"mplus_user_v1" servName:@"get_myorders_stat" params:@[@"yl_001001"]];
    [EXCSocketManager requestWithSocket:packet2 tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@">>>get_myorders_stat ");
    }];
    
    EXCSocketPacket *packet = [EXCSocketPacket packetWithUserName:@"yl_001001" servType:@"mplus_user_v1" servName:@"get_my_money" params:@[@"yl_001001"]];
    [EXCSocketManager requestWithSocket:packet tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@">>>get_my_money1");
    }];
    [EXCSocketManager requestWithSocket:packet tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@">>>get_my_money2");
    }];
    [EXCSocketManager requestWithSocket:packet tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@">>>get_my_money3");
    }];
    [EXCSocketManager requestWithSocket:packet tag:10 completed:^(NSString *rst, NSString *rstdes, NSArray *rstinfo) {
        NSLog(@">>>get_my_money4");
    }];
}
@end
