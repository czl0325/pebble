# pebble
mac设备如何通过编程通过usb数据线与hid设备通讯，以及如何通过串口通讯。


导入UsbHID头文件

```
#import "UsbHID.h"
```

配置usb的vid和pid

```
    usbHid = [[UsbHID alloc]initWithVID:0x1391 withPID:0x2111];
    usbHid.delegate = self;
```

实现代理
```
//usb接收到数据的代理
- (void)usbhidDidRecvData:(uint8_t*)recvData length:(CFIndex)reportLength;

//usb插入的代理
- (void)usbhidDidMatch;

//usb拔出的代理
- (void)usbhidDidRemove;

//发送数据的方法
- (void)senddata:(char*)outbuffer;
```
