//
//  UsbComposite.m
//  aardvark
//
//  Created by tpk on 14-10-13.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "UsbComposite.h"

@implementation UsbComposite

static UsbComposite *sharedInstance = nil;

void OperationCallBack(void *refcon, IOReturn result, void *arg0) {
    if (result == kIOReturnSuccess && refcon) {
        //u32 *pLen = (u32 *)refcon;
        //*pLen = reinterpret_cast<long>arg0;
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(id)init {
    self = [super init];
    if (self) {
        //v.p:0x0093,0x2510(鼠标)0x1391,0x2111(板)0x0951,0x1643(u盘)
        kOurVendorID = 0x0403;
        kOurProductID = 0xe0d0;
        arrayDevices = [NSMutableArray new];
    }
    return self;
}

+ (UsbComposite *)sharedUsbCompositeManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedInstance == nil)
            sharedInstance = [(UsbComposite *)[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedUsbCompositeManager];
}

- (id)copyWithZone:(NSZone *)zone
{
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

- (void)diveceAdd:(io_iterator_t)iterator
{
    // take care of the iterator here, making sure to complete iteration to re-arm it
    io_service_t service=0;
    while ((service=IOIteratorNext(iterator))!=0) {
        CFStringRef className;
        io_name_t name;
        className=IOObjectCopyClass(service);
        if((CFEqual(className, CFSTR("IOUSBService")))==true){
            IORegistryEntryGetName(service, name);
            printf("Found device with name:%s",name);
        }
        CFRelease(className);
        IOObjectRelease(service);
    }
}

-(BOOL)connectUSB {
    mach_port_t                 masterPort;
    CFMutableDictionaryRef      matchingDict;
    kern_return_t               kr = kIOReturnError;
    //SInt32                      usbVendor = 0x0403;
    //SInt32                      usbProduct = 0xe0d0;
    io_iterator_t               iter;
    
    kr = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if(kr != kIOReturnSuccess || !masterPort) {
        return kr;
    }
    
    //Set up matching dictionary for class IOUSBDevice and its subclass
    matchingDict = IOServiceMatching(kIOUSBDeviceClassName);
    if(!matchingDict) {
        return kr;
    }
    
    //Add the vendor and product IDs to the matching dictionary
    CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorName),
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &kOurVendorID));
    CFDictionarySetValue(matchingDict, CFSTR(kUSBProductName),
                         CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &kOurProductID));
    matchingDict = (CFMutableDictionaryRef)CFRetain(matchingDict);
    matchingDict = (CFMutableDictionaryRef)CFRetain(matchingDict);
    matchingDict = (CFMutableDictionaryRef)CFRetain(matchingDict);
    
    //Look up registered IOService objects that match a matching dictionary
    kr = IOServiceGetMatchingServices(masterPort, matchingDict, &iter);
    if (kr != kIOReturnSuccess || iter == 0) {
        mach_port_deallocate(mach_task_self(), masterPort);
        return kr;
    }
    
//    IONotificationPortRef notificationPort=NULL;
//    CFRunLoopSourceRef runLoopSource;
//    notificationPort=IONotificationPortCreate(masterPort);
//    runLoopSource=IONotificationPortGetRunLoopSource(notificationPort);
//    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
//    kr=IOServiceAddMatchingNotification(notificationPort,kIOMatchedNotification, matchingDict, diveceAdd, (__bridge void*)self, &iter);
//    kr=IOServiceAddMatchingNotification(notificationPort,kIOTerminatedNotification, matchingDict, diveceRemove, (__bridge void*)self, &iter);
//    //[self diveceAdd:iter];
//    return kr;
    
    //Get the usb device interface
    kr = [self GetUSBInterface:iter];
    if (kr != kIOReturnSuccess) {
        mach_port_deallocate(mach_task_self(), masterPort);
        IOObjectRelease(iter);
        return kr;
    }
    
    IOObjectRelease(iter);
    mach_port_deallocate(mach_task_self(), masterPort);
    return kr;
}

-(IOReturn) GetUSBInterface:(io_iterator_t) iterator {
    kern_return_t               kr = kIOReturnError;
    io_service_t                usbDevice;
    IOCFPlugInInterface         **plugInInterface = NULL;
    IOUSBDeviceInterface        **dev = NULL;
    HRESULT                     result;
    SInt32                      score;
    UInt16                      vendor;
    UInt16                      product;
    UInt16                      release;
    UInt32                      locationID;
    
    while((usbDevice = IOIteratorNext(iterator))) {
        //Create an intermediate plug-in
        kr = IOCreatePlugInInterfaceForService(usbDevice, kIOUSBDeviceUserClientTypeID,                                   kIOCFPlugInInterfaceID, &plugInInterface, &score);
        //Don't need the device object after intermediate plug-in is created
        kr = IOObjectRelease(usbDevice);
        if(kr != kIOReturnSuccess || !plugInInterface) {
            NSLog(@"Unable to create a plug-in (%08x)\n", kr);
            continue;
        }
        
        //Now create the device interface
        result = (*plugInInterface)->QueryInterface(plugInInterface,                       CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID), (LPVOID *)&dev);
        //Don't need the device object after intermediate plug-in is created
        IODestroyPlugInInterface(plugInInterface);
        if(result || !dev) {
            NSLog(@"Unable to create a device interface (%08x)\n",(int)result);
            continue;
        }
        if ([self IsDeviceExist:dev] == NO) {
            (*dev)->Release(dev);
            dev = NULL;
            continue;
        }
        
        //Check these values for confirmation
        kr = (*dev)->GetDeviceVendor(dev, &vendor);
        kr = (*dev)->GetDeviceProduct(dev, &product);
        kr = (*dev)->GetDeviceReleaseNumber(dev, &release);
        kr = (*dev)->GetLocationID(dev, &locationID);
        
        if(vendor != kOurVendorID || product != kOurProductID) {
            (void) (*dev)->Release(dev);
            dev = NULL;
            continue;
        } else {
            NSLog(@"Found allwinner usb device (vendor %04x, product %04x), location id %08x\n",vendor, product, locationID);
            //Open the device to change its state
            kr = (*dev)->USBDeviceOpen(dev);
            if(kr != kIOReturnSuccess) {
                (*dev)->USBDeviceClose(dev);
                (void) (*dev)->Release(dev);
                dev = NULL;
                continue;
            }
            
            //configure device
            UInt8                numConfig;
            IOUSBConfigurationDescriptorPtr configDesc;
            
            //Get the number of configurations.
            kr = (*dev)->GetNumberOfConfigurations(dev, &numConfig);
            if(numConfig == 0)
                continue;
            
            //Get the configuration descriptor for index 0
            kr = (*dev)->GetConfigurationDescriptorPtr(dev, 0, &configDesc);
            if(kr) {
                NSLog(@"Unable to get configuration descriptor for index 0 (err = %08x)\n",kr);
                continue;
            }
#if 0
            kr = (*dev)->SetConfiguration(dev, configDesc->bConfigurationValue);
            if(kr) {
                NSLog(@"Unable to set configuration to value %d (err = %08x)\n",0, kr);
                continue;
            }
#endif
            kr = [self FindUSBInterface:dev];
            if (kr != kIOReturnSuccess) {
                (*dev)->USBDeviceClose(dev);
                (*dev)->Release(dev);
                dev = NULL;
            }
        }
    }
    return kr;
}

-(IOReturn) FindUSBInterface:(IOUSBDeviceInterface **)dev
{
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
    kr = (*dev)->CreateInterfaceIterator(dev, &request, &iterator);
    if(kr != kIOReturnSuccess) {
        NSLog(@"Unable to CreateInterfaceIterator %08x\n", kr);
        return kr;
    }
    
    kr = kIOReturnError;
    while((usbInterface = IOIteratorNext(iterator))) {
        pipeIn = 0xff;
        pipeOut = 0xff;
        //Create a intermediate plug-in
        kr = IOCreatePlugInInterfaceForService(usbInterface,                                               kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID,                                               &plugInInterface, &score);
        //Release the usbInterface object after getting the plug-in
        kr = IOObjectRelease(usbInterface);
        if(kr != kIOReturnSuccess || !plugInInterface) {
            NSLog(@"Unable to create a plug-in (%08x)\n", kr);
            break;
        }
        
        //Now create the device interface for the device interface
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
            NSAlert* alert = [NSAlert alertWithMessageText:@"error" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"USBInterfaceOpen error!"];
            [alert runModal];
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
            DeviceObject* pDev = [[DeviceObject alloc]init];
            pDev.dev = dev;
            pDev.interface = interface;
            pDev.pipeIn = pipeIn;
            pDev.pipeOut = pipeOut;
            pDev.maxPacketSizeIn = maxPacketSizeIn;
            pDev.maxPacketSizeOut = maxPacketSizeOut;
            UInt32 lid ;
            (*dev)->GetLocationID(dev, &lid);
            pDev.locationID = lid;
            [arrayDevices addObject:pDev];
            return kIOReturnSuccess;
        }
        (*interface)->USBInterfaceClose(interface);
        (*interface)->Release(interface);
        interface = NULL;
    }
    
    return kr;
}

-(BOOL)IsDeviceExist:(IOUSBDeviceInterface **)dev{
    if (!dev) {
        return NO;
    }
    
    UInt32 locationID;
    kern_return_t kr;
    kr = (*dev)->GetLocationID(dev, &locationID);
    if(kr != kIOReturnSuccess) {
        NSLog(@"GetLocationID failed\n");
        return NO;
    }
    
    return YES;
}

void ReadCompletion(void *refCon, IOReturn result, void *arg0) {
    IOUSBInterfaceInterface **interface =(IOUSBInterfaceInterface **) refCon;
    
    if (result != kIOReturnSuccess) {
        (void) (*interface)->USBInterfaceClose(interface);
        (void) (*interface)->Release(interface);
        return;
    }
}

//同步
-(IOReturn)WriteSync:(DeviceObject*)pDev buffer:(char*) writeBuffer size:(u32)size
{
    if (pDev && pDev.interface) {
        if(size <= pDev.maxPacketSizeOut) {
            return [self WriteAsync:pDev buffer:writeBuffer size:size];
        }
        kern_return_t kr = 0;
        char *tmp = writeBuffer;
        u32 nWrite = (size > pDev.maxPacketSizeOut ? pDev.maxPacketSizeOut : size);
        u32 nLeft = size;
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
-(IOReturn)WriteAsync:(DeviceObject*)pDev buffer:(char*)writeBuffer size:(u32)size {
    if (pDev == nil||pDev.interface == nil) {
        return kIOReturnNoDevice;
    }
    
    IOReturn                  err;
    CFRunLoopSourceRef        cfSource;
    u32*                      pWrite;
    
    err = (*(pDev.interface))->CreateInterfaceAsyncEventSource(pDev.interface, &cfSource);
    if (err) {
        NSLog(@"transferData: unable to create event source, err = %08x\n", err);
        return err;
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    err = (*(pDev.interface))->WritePipeAsync(pDev.interface, pDev.pipeOut, (void *)writeBuffer, size,                                         (IOAsyncCallback1)OperationCallBack, (void*)pWrite);
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

-(IOReturn)ReadSync:(DeviceObject*)pDev buffer:(char*)buff size:(u32)size {
    if (pDev && pDev.interface) {
        if(sizeof(buff) <= pDev.maxPacketSizeIn) {
            return [self ReadAsync:pDev buffer:buff size:size];
        }
        kern_return_t kr = 0;
        UInt32 nRead = pDev.maxPacketSizeIn;
        u32 nLeft = size;
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

-(IOReturn)ReadAsync:(DeviceObject*)pDev buffer:(char*)buff size:(u32)size {
    if (pDev == nil||pDev.interface == nil) {
        return kIOReturnNoDevice;
    }
    
    IOReturn                    err;
    CFRunLoopSourceRef          cfSource;
    u32*                        pRead;
    
    err = (*(pDev.interface))->CreateInterfaceAsyncEventSource(pDev.interface, &cfSource);
    if (err) {
        NSLog(@"transferData: unable to create event source, err = %08x\n", err);
        return err;
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), cfSource, kCFRunLoopDefaultMode);
    
    err = (*(pDev.interface))->ReadPipeAsync(pDev.interface, pDev.pipeIn, buff, size,(IOAsyncCallback1)OperationCallBack, (void*)pRead);
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

-(NSMutableArray*)getDeviceArray {
    return arrayDevices;
}

@end
