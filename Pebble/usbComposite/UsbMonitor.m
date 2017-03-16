//
//  UsbMonitor.m
//  aardvark
//
//  Created by tpk on 14-11-21.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "UsbMonitor.h"

@implementation UsbMonitor

@synthesize arrayDevices;
@synthesize delegate;

static UsbMonitor *sharedInstance = nil;

IONotificationPortRef	gNotifyPort;
io_iterator_t			gAddedIter;
CFRunLoopRef			gRunLoop;


void SignalHandler(int sigraised) {
    fprintf(stderr, "\nInterrupted.\n");
    exit(0);
}

void DeviceNotification(void *refCon, io_service_t service, natural_t messageType, void *messageArgument) {
    kern_return_t	kr;
    DeviceObject	*privateDataRef = (__bridge DeviceObject *) refCon;
    
    if (messageType == kIOMessageServiceIsTerminated) {
        for (DeviceObject* usbObj in [UsbMonitor sharedUsbMonitorManager].arrayDevices) {
            if (usbObj.locationID == privateDataRef.locationID) {
                NSLog(@"delete id=%08x",usbObj.locationID);
                [[UsbMonitor sharedUsbMonitorManager].arrayDevices removeObject:usbObj];
                break;
            }
        }
        
        if ([[UsbMonitor sharedUsbMonitorManager].delegate respondsToSelector:@selector(usbDidRemove:)]) {
            [[UsbMonitor sharedUsbMonitorManager].delegate usbDidRemove:privateDataRef];
        }
        
        CFRelease(privateDataRef.deviceName);
        
        if (privateDataRef.interface) {
            (*(privateDataRef.interface))->USBInterfaceClose(privateDataRef.interface);
            (*(privateDataRef.interface))->Release(privateDataRef.interface);
        }
        
        if (privateDataRef.dev) {
            (*(privateDataRef.dev))->USBDeviceClose(privateDataRef.dev);
            kr = (*privateDataRef.dev)->Release(privateDataRef.dev);
        }
        
        kr = IOObjectRelease(privateDataRef.notification);
    }
}

void DeviceAdded(void *refCon, io_iterator_t iterator) {
    kern_return_t		kr;
    io_service_t		usbDevice;
    IOCFPlugInInterface	**plugInInterface = NULL;
    SInt32				score;
    HRESULT 			res;
    
    while ((usbDevice = IOIteratorNext(iterator))) {
        io_name_t		deviceName;
        CFStringRef		deviceNameAsCFString;
        DeviceObject	*privateDataRef = [[DeviceObject alloc]init];
        UInt32			locationID;
        
        kr = IORegistryEntryGetName(usbDevice, deviceName);
        if (KERN_SUCCESS != kr) {
            deviceName[0] = '\0';
        }
        
        deviceNameAsCFString = CFStringCreateWithCString(kCFAllocatorDefault,deviceName,kCFStringEncodingASCII);
        //NSLog(@"deviceName:%@",deviceNameAsCFString);
        
        privateDataRef.deviceName = deviceNameAsCFString;
        kr = IOCreatePlugInInterfaceForService(usbDevice,kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID,&plugInInterface, &score);
        
        if ((kIOReturnSuccess != kr) || !plugInInterface) {
            NSLog(@"IOCreatePlugInInterfaceForService returned 0x%08x.",kr);
            continue;
        }
        
        IOUSBDeviceInterface     **oneDev = NULL;
        res = (*plugInInterface)->QueryInterface(plugInInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),(LPVOID*)&oneDev);
        privateDataRef.dev = oneDev;
        
        (*plugInInterface)->Release(plugInInterface);
        if (res || privateDataRef.dev == NULL) {
            NSLog(@"QueryInterface returned %d.\n", (int)res);
            continue;
        }
        
        kr = (*privateDataRef.dev)->GetLocationID(privateDataRef.dev, &locationID);
        if (KERN_SUCCESS != kr) {
            NSLog(@"GetLocationID returned 0x%08x.\n", kr);
            continue;
        } else {
            NSLog(@"Location ID: 0x%08x", locationID);
        }
        privateDataRef.locationID = locationID;
        
        kr = (*privateDataRef.dev)->USBDeviceOpen(privateDataRef.dev);
        if(kr != kIOReturnSuccess) {
            NSLog(@"Usb Open Fail!");
            (*privateDataRef.dev)->USBDeviceClose(privateDataRef.dev);
            (void) (*privateDataRef.dev)->Release(privateDataRef.dev);
            privateDataRef.dev = NULL;
            continue;
        }
        
        //configure device
        UInt8                numConfig;
        IOUSBConfigurationDescriptorPtr configDesc;
        
        //Get the number of configurations.
        kr = (*privateDataRef.dev)->GetNumberOfConfigurations(privateDataRef.dev, &numConfig);
        if(numConfig == 0)
            continue;
        
        //Get the configuration descriptor for index 0
        kr = (*privateDataRef.dev)->GetConfigurationDescriptorPtr(privateDataRef.dev, 0, &configDesc);
        if(kr != kIOReturnSuccess) {
            NSLog(@"Unable to get configuration descriptor for index 0 (err = %08x)\n",kr);
            continue;
        }
        kr = [[UsbMonitor sharedUsbMonitorManager] FindUSBInterface:privateDataRef];
        if (kr != kIOReturnSuccess) {
            NSLog(@"Interface Open Fail!");
            (*privateDataRef.dev)->USBDeviceClose(privateDataRef.dev);
            (*privateDataRef.dev)->Release(privateDataRef.dev);
            privateDataRef.dev = NULL;
            continue ;
        }
        
        io_object_t              oneIter;
        kr = IOServiceAddInterestNotification(gNotifyPort,usbDevice,kIOGeneralInterest,	DeviceNotification,(__bridge void*)privateDataRef,&oneIter);
        privateDataRef.notification = oneIter;
        
        if (KERN_SUCCESS != kr) {
            NSLog(@"IOServiceAddInterestNotification returned 0x%08x", kr);
        }
        
        kr = IOObjectRelease(usbDevice);
    }
}

void usbMonitorCallBack(void *refcon, IOReturn result, void *arg0) {
    if (result == kIOReturnSuccess && refcon) {
        //u32 *pLen = (u32 *)refcon;
        //*pLen = reinterpret_cast<long>arg0;
    }
    NSLog(@"read and write callback!");
    CFRunLoopStop(CFRunLoopGetCurrent());
}


+ (UsbMonitor *)sharedUsbMonitorManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedInstance == nil)
            sharedInstance = [(UsbMonitor *)[super allocWithZone:NULL] init];
    });
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedUsbMonitorManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)initWithVID:(long)vid withPID:(long)pid {
    self = [super init];
    if (self) {
        arrayDevices = [NSMutableArray new];
        
        CFMutableDictionaryRef 	matchingDict;
        CFRunLoopSourceRef		runLoopSource;
        CFNumberRef				numberRef;
        kern_return_t			kr;
        long					usbVendor = vid;
        long					usbProduct = pid;
        
        matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
        if (matchingDict == NULL) {
            return nil;
        }
        
        numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
        CFDictionarySetValue(matchingDict,CFSTR(kUSBVendorID),numberRef);
        CFRelease(numberRef);
        
        numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbProduct);
        CFDictionarySetValue(matchingDict,CFSTR(kUSBProductID),numberRef);
        CFRelease(numberRef);
        numberRef = NULL;
        
        gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
        
        gRunLoop = CFRunLoopGetCurrent();
        CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
        
        kr = IOServiceAddMatchingNotification(gNotifyPort,kIOFirstMatchNotification,matchingDict,DeviceAdded,NULL,&gAddedIter);
        
        DeviceAdded(NULL, gAddedIter);
        
        CFRunLoopRun();
        
    }
    return self;
}

- (id)initWithVID:(long)vid withPID:(long)pid withDelegate:(id<UsbMonitorDelegate>)gate {
    self = [super init];
    if (self) {
        arrayDevices = [NSMutableArray new];
        
        CFMutableDictionaryRef 	matchingDict;
        CFRunLoopSourceRef		runLoopSource;
        CFNumberRef				numberRef;
        kern_return_t			kr;
        long					usbVendor = vid;
        long					usbProduct = pid;
        delegate = gate;
//        sig_t					oldHandler;
//        
//        oldHandler = signal(SIGINT, SignalHandler);
//        if (oldHandler == SIG_ERR) {
//            fprintf(stderr, "Could not establish new signal handler.");
//        }
        
        matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
        if (matchingDict == NULL) {
            return nil;
        }
        
        numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
        CFDictionarySetValue(matchingDict,CFSTR(kUSBVendorID),numberRef);
        CFRelease(numberRef);
        
        numberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbProduct);
        CFDictionarySetValue(matchingDict,CFSTR(kUSBProductID),numberRef);
        CFRelease(numberRef);
        numberRef = NULL;
        
        gNotifyPort = IONotificationPortCreate(kIOMasterPortDefault);
        runLoopSource = IONotificationPortGetRunLoopSource(gNotifyPort);
        
        gRunLoop = CFRunLoopGetCurrent();
        CFRunLoopAddSource(gRunLoop, runLoopSource, kCFRunLoopDefaultMode);
        
        kr = IOServiceAddMatchingNotification(gNotifyPort,kIOFirstMatchNotification,matchingDict,DeviceAdded,NULL,&gAddedIter);
        
        DeviceAdded(NULL, gAddedIter);
        
        CFRunLoopRun();

    }
    return self;
}

-(void)dealloc {
    for (DeviceObject* dev in arrayDevices) {
        (*(dev.interface))->USBInterfaceClose(dev.interface);
        (*(dev.interface))->Release(dev.interface);
        (*(dev.dev))->USBDeviceClose(dev.dev);
        (*(dev.dev))->Release(dev.dev);
    }
    [arrayDevices removeAllObjects];
}

-(IOReturn) FindUSBInterface:(DeviceObject*)usbObject {
    IOReturn                        kr = kIOReturnError;
    IOUSBFindInterfaceRequest       request;
    io_iterator_t                   iterator;
    io_service_t                    usbInterface;
    IOCFPlugInInterface             **plugInInterface = NULL;
    IOUSBInterfaceInterface         **interface = NULL;
    HRESULT                         result;
    SInt32                          score;
    UInt8                           interfaceNumEndpoints;
    UInt8                           pipeRef;
    UInt16                          maxPacketSize = 0;
    UInt8                           pipeIn = 0xff;
    UInt8                           pipeOut = 0xff;
    UInt16                          maxPacketSizeIn = 0;
    UInt16                          maxPacketSizeOut = 0;
    
    //Iterate all usb interface
    request.bInterfaceClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting = kIOUSBFindInterfaceDontCare;
    
    //Get an iterator for the interfaces on the device
    kr = (*usbObject.dev)->CreateInterfaceIterator(usbObject.dev, &request, &iterator);
    if(kr != kIOReturnSuccess) {
        NSLog(@"Unable to CreateInterfaceIterator %08x\n", kr);
        return kr;
    }
    
    kr = kIOReturnError;
    while((usbInterface = IOIteratorNext(iterator))) {
        pipeIn = 0xff;
        pipeOut = 0xff;
        kr = IOCreatePlugInInterfaceForService(usbInterface,                                               kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID,                                               &plugInInterface, &score);
        kr = IOObjectRelease(usbInterface);
        if(kr != kIOReturnSuccess || !plugInInterface) {
            NSLog(@"Unable to create a plug-in (%08x)\n", kr);
            break;
        }
        
        result = (*plugInInterface)->QueryInterface(plugInInterface,                           CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), (LPVOID *)&interface);
        IODestroyPlugInInterface(plugInInterface);
        if(result || !interface) {
            NSLog(@"Unable to create a interface for the device interface %08x\n",(int)result);
            break;
        }
        //kr = (*interface)->USBInterfaceClose(interface);
        kr = (*interface)->USBInterfaceOpen(interface);
        if(kr != kIOReturnSuccess) {
            NSLog(@"Unable to open interface for the device interface %08x\n", kr);
            (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            interface = NULL;
            break;
        }
        kr = (*interface)->GetNumEndpoints(interface, &interfaceNumEndpoints);
        if(kr != kIOReturnSuccess) {
            (void) (*interface)->USBInterfaceClose(interface);
            (void) (*interface)->Release(interface);
            interface = NULL;
            break;
        }
        for(pipeRef = 1; pipeRef <= interfaceNumEndpoints; pipeRef++) {
            IOReturn     kr2;
            UInt8        direction;
            UInt8        number;
            UInt8        transferType;
            UInt8        interval;
            
            kr2 = (*interface)->GetPipeProperties(interface, pipeRef, &direction,&number, &transferType, &maxPacketSize, &interval);
            if(kr2 != kIOReturnSuccess) {
                NSLog(@"Unable to get properties of pipe %d (%08x)\n",pipeRef, kr2);
            } else {
                if(transferType == kUSBBulk) {
                    if(direction == kUSBIn) {
                        pipeIn = pipeRef;
                        maxPacketSizeIn = maxPacketSize;
                    }
                    else if(direction == kUSBOut) {
                        pipeOut = pipeRef;
                        maxPacketSizeOut = maxPacketSize;
                    }
                }
            }
        }
        if (pipeIn != 0xff && pipeOut != 0xff) {
            usbObject.interface = interface;
            usbObject.pipeIn = pipeIn;
            usbObject.pipeOut = pipeOut;
            usbObject.maxPacketSizeIn = maxPacketSizeIn;
            usbObject.maxPacketSizeOut = maxPacketSizeOut;
            BOOL isIn = NO;
            for (DeviceObject* obj in arrayDevices) {
                if (obj.locationID == usbObject.locationID) {
                    isIn = YES;
                    break ;
                }
            }
            if (!isIn) {
                [arrayDevices addObject:usbObject];
            }
            if ([delegate respondsToSelector:@selector(usbDidPlunIn:)]) {
                [delegate usbDidPlunIn:usbObject];
            }
            return kIOReturnSuccess;
        }
        (*interface)->USBInterfaceClose(interface);
        (*interface)->Release(interface);
        interface = NULL;
    }
    return kr;
}

- (DeviceObject*)getObjectByID:(long)localid {
    for (DeviceObject* obj in arrayDevices) {
        if (obj.locationID == localid) {
            return obj;
        }
    }
    return nil;
}

//同步
-(IOReturn)WriteSync:(DeviceObject*)pDev buffer:(char*) writeBuffer size:(unsigned int)size
{
    if (pDev && pDev.interface) {
        if(size <= pDev.maxPacketSizeOut) {
            return [self WriteAsync:pDev buffer:writeBuffer size:size];
        }
        kern_return_t kr = 0;
        char *tmp = writeBuffer;
        unsigned int nWrite = (size > pDev.maxPacketSizeOut ? pDev.maxPacketSizeOut : size);
        unsigned int nLeft = size;
        while(1) {
            if((int)nLeft <= 0) {
                break;
            }
            kr = (*(pDev.interface))->WritePipe(pDev.interface,pDev.pipeOut, (void *)tmp, nWrite);
            if(kr != kIOReturnSuccess)
                break;
            tmp += nWrite;
            nLeft -= nWrite;
            nWrite = (nLeft > pDev.maxPacketSizeOut ? pDev.maxPacketSizeOut : nLeft);
        }
        return kr;
    }
    
    return kIOReturnNoDevice;
}

//异步
-(IOReturn)WriteAsync:(DeviceObject*)pDev buffer:(char*)writeBuffer size:(unsigned int)size {
    if (pDev == nil||pDev.interface == nil) {
        return kIOReturnNoDevice;
    }
    
    IOReturn                  err;
    CFRunLoopSourceRef        cfSource;
    unsigned int*             pWrite;
    
    err = (*(pDev.interface))->CreateInterfaceAsyncEventSource(pDev.interface, &cfSource);
    if (err) {
        NSLog(@"transferData: unable to create event source, err = %08x\n", err);
        return err;
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    err = (*(pDev.interface))->WritePipeAsync(pDev.interface, pDev.pipeOut, (void *)writeBuffer, size,                                         (IOAsyncCallback1)usbMonitorCallBack, (void*)pWrite);
    if (err != kIOReturnSuccess) {
        NSLog(@"transferData: WritePipeAsyncFailed, err = %08x\n", err);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
        *pWrite = 0;
        return err;
    }
    
    CFRunLoopRun();
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    return err;
}

-(IOReturn)ReadSync:(DeviceObject*)pDev buffer:(char*)buff size:(unsigned int)size {
    if (pDev && pDev.interface) {
        if(sizeof(buff) <= pDev.maxPacketSizeIn) {
            return [self ReadAsync:pDev buffer:buff size:size];
        }
        kern_return_t kr = 0;
        UInt32 nRead = pDev.maxPacketSizeIn;
        unsigned int nLeft = size;
        char *tmp = (char *)buff;
        
        while(1) {
            if((int)nLeft <= 0)
                break;
            
            kr = (*(pDev.interface))->ReadPipe(pDev.interface,                   pDev.pipeIn, (void *)tmp, &nRead);
            if(kr != kIOReturnSuccess) {
                printf("transferData: Readsync Failed, err = %08x\n", kr);
                break;
            }
            
            tmp += nRead;
            nLeft -= nRead;
            nRead = pDev.maxPacketSizeIn;
        }
        int nRet = ((int)nLeft > 0 ? nLeft : 0);
        size = size - nRet;
        return kr;
    }
    return kIOReturnNoDevice;
}

-(IOReturn)ReadAsync:(DeviceObject*)pDev buffer:(char*)buff size:(unsigned int)size {
    if (pDev == nil||pDev.interface == nil) {
        return kIOReturnNoDevice;
    }
    
    IOReturn                    err;
    CFRunLoopSourceRef          cfSource;
    unsigned int*               pRead;
    
    err = (*(pDev.interface))->CreateInterfaceAsyncEventSource(pDev.interface, &cfSource);
    if (err) {
        NSLog(@"transferData: unable to create event source, err = %08x\n", err);
        return err;
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    err = (*(pDev.interface))->ReadPipeAsync(pDev.interface, pDev.pipeIn, buff, size,(IOAsyncCallback1)usbMonitorCallBack, (void*)pRead);
    if (err != kIOReturnSuccess) {
        NSLog(@"transferData: size %u, ReadAsyncFailed, err = %08x\n", size, err);
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
        pRead = nil;
        pDev = nil;
        return err;
    }
    
    CFRunLoopRun();
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    return err;
}

- (NSMutableArray*)getDeviceArray {
    return arrayDevices;
}

@end
