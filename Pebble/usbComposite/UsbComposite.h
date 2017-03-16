//
//  UsbComposite.h
//  aardvark
//
//  Created by tpk on 14-10-13.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "DeviceObject.h"

typedef unsigned int u32;

@interface UsbComposite : NSObject{
    int kOurVendorID;
    int kOurProductID;
    char readbuff[64];
    NSMutableArray* arrayDevices;
}

+(UsbComposite *)sharedUsbCompositeManager;
-(BOOL)connectUSB;
-(BOOL)IsDeviceExist:(IOUSBDeviceInterface **)dev;
-(IOReturn)WriteSync:(DeviceObject*)pDev buffer:(char*) writeBuffer size:(u32)size
;
-(IOReturn)WriteAsync:(DeviceObject*)pDev buffer:(char*)writeBuffer size:(u32)size ;
-(IOReturn)ReadSync:(DeviceObject*)pDev buffer:(char*)buff size:(u32)size;
-(IOReturn)ReadAsync:(DeviceObject*)pDev buffer:(char*)buff size:(u32)size;
-(NSMutableArray*)getDeviceArray;

@end
