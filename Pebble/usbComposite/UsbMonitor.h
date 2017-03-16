//
//  UsbMonitor.h
//  aardvark
//
//  Created by tpk on 14-11-21.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/IOMessage.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/usb/IOUSBLib.h>
#import "DeviceObject.h"

@protocol UsbMonitorDelegate <NSObject>
@optional
- (void)usbDidPlunIn:(DeviceObject*)usbObject;
- (void)usbDidRemove:(DeviceObject*)usbObject;
@end

@interface UsbMonitor : NSObject {
}

@property(nonatomic,strong)NSMutableArray* arrayDevices;
@property(nonatomic,strong)id<UsbMonitorDelegate> delegate;

+ (UsbMonitor *)sharedUsbMonitorManager;
- (id)initWithVID:(long)vid withPID:(long)pid;
- (id)initWithVID:(long)vid withPID:(long)pid withDelegate:(id<UsbMonitorDelegate>)gate;
- (DeviceObject*)getObjectByID:(long)localid;
- (IOReturn)WriteSync:(DeviceObject*)pDev buffer:(char*) writeBuffer size:(unsigned int)size;
- (IOReturn)WriteAsync:(DeviceObject*)pDev buffer:(char*)writeBuffer size:(unsigned int)size;
- (IOReturn)ReadSync:(DeviceObject*)pDev buffer:(char*)buff size:(unsigned int)size;
- (IOReturn)ReadAsync:(DeviceObject*)pDev buffer:(char*)buff size:(unsigned int)size;
- (NSMutableArray*)getDeviceArray;

@end
