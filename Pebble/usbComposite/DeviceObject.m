//
//  DeviceObject.m
//  macusb
//
//  Created by tpk on 14-8-13.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "DeviceObject.h"

@implementation DeviceObject

@synthesize notification;
@synthesize interface;
@synthesize locationID;
@synthesize deviceName;

@synthesize dev;
@synthesize pipeIn;
@synthesize pipeOut;
@synthesize maxPacketSizeIn;
@synthesize maxPacketSizeOut;

@end
