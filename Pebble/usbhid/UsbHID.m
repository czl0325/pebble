//
//  UsbHID.m
//  Bamboo
//
//  Created by tpk on 14-9-11.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "UsbHID.h"
#import <Cocoa/Cocoa.h>
#import "Header.h"

@implementation UsbHID

static UsbHID *_sharedManager = nil;

@synthesize delegate;

static void MyInputCallback(void* context, IOReturn result, void* sender, IOHIDReportType type, uint32_t reportID, uint8_t *report,CFIndex reportLength) {
    [[[UsbHID sharedManager] delegate] usbhidDidRecvData:report length:reportLength];
}

static void Handle_DeviceMatchingCallback(void *inContext,IOReturn inResult,void *inSender,IOHIDDeviceRef inIOHIDDeviceRef) {
    [[UsbHID sharedManager] setDeviceRef:inIOHIDDeviceRef];
    char *inputbuffer = malloc(64);
    IOHIDDeviceRegisterInputReportCallback([[UsbHID sharedManager]getDeviceRef], (uint8_t*)inputbuffer, 64, MyInputCallback, NULL);
#ifdef TEST
    NSLog(@"%p设备插入,现在usb设备数量:%ld",(void *)inIOHIDDeviceRef,USBDeviceCount(inSender));
#endif
    [[[UsbHID sharedManager] delegate] usbhidDidMatch];
}

static void Handle_DeviceRemovalCallback(void *inContext,IOReturn inResult,void *inSender,IOHIDDeviceRef inIOHIDDeviceRef) {
    [[UsbHID sharedManager] setDeviceRef:nil];
#ifdef TEST
    NSLog(@"%p设备拔出,现在usb设备数量:%ld",(void *)inIOHIDDeviceRef,USBDeviceCount(inSender));
#endif
    [[[UsbHID sharedManager] delegate] usbhidDidRemove];
}

#ifdef TEST
static long USBDeviceCount(IOHIDManagerRef HIDManager){
    CFSetRef devSet = IOHIDManagerCopyDevices(HIDManager);
    if(devSet)
        return CFSetGetCount(devSet);
    return 0;
}
#endif

+(UsbHID *)sharedManager {
    @synchronized( [UsbHID class] ){
        if(!_sharedManager)
            _sharedManager = [[self alloc] init];
        return _sharedManager;
    }
    return nil;
}

+(id)alloc {
    @synchronized ([UsbHID class]){
        NSAssert(_sharedManager == nil,
                 @"Attempted to allocated a second instance");
        _sharedManager = [super alloc];
        return _sharedManager;
    }
    return nil;
}

- (id)initWithVID:(long)vid withPID:(long)pid {
    self = [super init];
    if (self) {
        managerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        IOReturn ret = IOHIDManagerOpen(managerRef, kIOHIDOptionsTypeNone);
        if (ret != kIOReturnSuccess) {
            NSAlert* alert = [NSAlert alertWithMessageText:@"error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"打开设备失败!"];
            [alert runModal];
            return self;
        }
        const long vendorID = vid;
        const long productID = pid;
        NSMutableDictionary* dict= [NSMutableDictionary dictionary];
        [dict setValue:[NSNumber numberWithLong:productID] forKey:[NSString stringWithCString:kIOHIDProductIDKey encoding:NSUTF8StringEncoding]];
        [dict setValue:[NSNumber numberWithLong:vendorID] forKey:[NSString stringWithCString:kIOHIDVendorIDKey encoding:NSUTF8StringEncoding]];
        IOHIDManagerSetDeviceMatching(managerRef, (__bridge CFMutableDictionaryRef)dict);
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, &Handle_DeviceMatchingCallback, NULL);
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, &Handle_DeviceRemovalCallback, NULL);
        
        NSSet* allDevices = (__bridge NSSet*)(IOHIDManagerCopyDevices(managerRef));
        NSArray* deviceRefs = [allDevices allObjects];
        if (deviceRefs.count==0) {
            
        }
    }
    return self;
}

- (void)dealloc {
    IOReturn ret = IOHIDDeviceClose(deviceRef, 0L);
    if (ret == kIOReturnSuccess) {
        deviceRef = nil;
    }
    ret = IOHIDManagerClose(managerRef, 0L);
    if (ret == kIOReturnSuccess) {
        managerRef = nil;
    }
}

- (void)connectHID {
    NSSet* allDevices = (__bridge NSSet*)(IOHIDManagerCopyDevices(managerRef));
    NSArray* deviceRefs = [allDevices allObjects];
    deviceRef = (deviceRefs.count)?(__bridge IOHIDDeviceRef)[deviceRefs objectAtIndex:0]:nil;
}

- (void)senddata:(char*)outbuffer {
    if (!deviceRef) {
        return ;
    }
#ifdef TEST
    NSLog(@"发送%02x,%02x,%02x",outbuffer[0],outbuffer[1],outbuffer[2]);
    //NSString* str = [NSString stringWithFormat:@"发送%02x,%02x,%02x\n",outbuffer[0],outbuffer[1],outbuffer[2]];
    //writeTestData(str);
#endif
    IOReturn ret = IOHIDDeviceSetReport(deviceRef, kIOHIDReportTypeOutput, 0, (uint8_t*)outbuffer, sizeof(outbuffer));
    if (ret != kIOReturnSuccess) {
        NSAlert* alert = [NSAlert alertWithMessageText:@"error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Send Data Error!"];
        [alert runModal];
    }
}

- (IOHIDManagerRef)getManageRef {
    return managerRef;
}

- (void)setManageRef:(IOHIDManagerRef)ref {
    managerRef = ref;
}

- (IOHIDDeviceRef)getDeviceRef {
    return deviceRef;
}

- (void)setDeviceRef:(IOHIDDeviceRef)ref {
    deviceRef = ref;
}





@end
