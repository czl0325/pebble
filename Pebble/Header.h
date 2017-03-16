//
//  Header.h
//  Margaux-OQC
//
//  Created by tpk on 14-12-3.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#ifndef Margaux_Header_h
#define Margaux_Header_h

#import "NSTools.h"
#import "NSViewExt.h"
#import "NSWindowExt.h"
#import "NSDate-Utilities.h"
#import "CSVObject.h"
#import "BCView.h"
#import "LXScrubbingBar.h"
#import "MyTextView.h"
#import "UsbHID.h"
#import "JNWAnimatableWindow.h"
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#import "ScrollingTextView.h"
#import <QuartzCore/QuartzCore.h>
#import "DJProgressHUD.h"

#define barcodelength       16
#define ONEPACKAGE          29
#define ALLPIN              45

#define TEXTCOLOR [NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0.4 alpha:1.0]
#define TEXTFAILCOLOR      [NSColor redColor]
#define TEXTPASSCOLOR   [NSColor blackColor]
#define PASSCOLOR  [NSColor colorWithCalibratedRed:0.0 green:100.0/255.0 blue:0.0 alpha:1.0]

#define BYTETOWORD(b1,b2) ((b1<<8)|b2)
#define BYTETOBCD(bcd) (bcd&15)+((bcd>>4)*10)
#define BYTETOSHORT(b1,b2) (short)(((b1&0xff)<<8)|(b2&0xff))

//#define TEST
#define C2400
#define ALLCSV

#endif
