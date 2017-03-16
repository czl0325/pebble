//
//  UsbHID.h
//  Bamboo
//
//  Created by tpk on 14-9-11.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/hid/IOHIDKeys.h>

@protocol UsbHIDDelegate <NSObject>
@optional
- (void)usbhidDidRecvData:(uint8_t*)recvData length:(CFIndex)reportLength;
- (void)usbhidDidMatch;
- (void)usbhidDidRemove;
@end

@interface UsbHID : NSObject {
    IOHIDManagerRef managerRef;
    IOHIDDeviceRef deviceRef;
}

@property(nonatomic,strong)id<UsbHIDDelegate> delegate;

+ (UsbHID *)sharedManager;
- (id)initWithVID:(long)vid withPID:(long)pid;
- (void)connectHID;
- (void)senddata:(char*)outbuffer;
- (IOHIDManagerRef)getManageRef;
- (void)setManageRef:(IOHIDManagerRef)ref;
- (IOHIDDeviceRef)getDeviceRef;
- (void)setDeviceRef:(IOHIDDeviceRef)ref;

@end
