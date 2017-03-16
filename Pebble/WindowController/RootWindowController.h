//
//  RootWindowController.h
//  Margaux
//
//  Created by tpk on 15-1-13.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Header.h"
#import "ColorView.h"
#import "KeyBoardTextField.h"
#import "TSPCircularProgressIndicator.h"

#define SHORTFORMULA(x)  ((x*5)/4096.0)

@interface RootWindowController : NSWindowController
<NSWindowDelegate,UsbHIDDelegate,ORSSerialPortDelegate,
NSUserNotificationCenterDelegate,KeyBoardTextFieldDelegate>{
    UsbHID* usbHid;
    ORSSerialPort* multimeterPort;      //万用表
    float m_Grain;
    BOOL isUP;
    NSString* multimeterCommString;
    CFAbsoluteTime timeStart;
    CFAbsoluteTime timeEnd;
    NSDate* dateStart;
    NSDate* dateEnd;
    BOOL xPass;
    BOOL yPass;
    BOOL uPass;
    BOOL shortPass;
    BOOL allPass;
    BOOL isWaitData;
    NSDate* dateForStartWait;
    int m_nProgress;
    NSString* strErrorCode;
    int testPIN;
    int axis;
    NSMutableArray* xArray;
    NSMutableArray* yArray;
    NSMutableArray* xShort;
    NSMutableArray* yShort;
    float m_fMaxRes;
    float m_fMinRes;
    float m_fMinShort;
    float m_fUMax;
    NSArray* m_uRange;
    float frontGap;
    float backGap;
    float uMax;
    NSMutableArray* arrayResData;
    NSTimer *timerTest;
    float m_fTimeStamp;
    BOOL isRunAlert;
#ifdef ALLCSV
    NSString* strLOG;
    NSString* strCSV;
    CSVObject* logObject;
    CSVObject* csvObject;
#endif
    
    IBOutlet NSImageView* imageBackView;
    IBOutlet BCView* backView;
    IBOutlet TSPCircularProgressIndicator* progressBar;
    IBOutlet NSImageView* imageViewUsb;
    IBOutlet NSImageView* imageViewComm;
    IBOutlet MyTextView* textViewResult;
    IBOutlet NSButton* btStart;
    IBOutlet ScrollingTextView* scrollTextView;
    IBOutlet KeyBoardTextField* textFieldSN;
    IBOutlet NSTextField* textPassOrFail;
    IBOutlet NSTextField* textPassNum;
    IBOutlet NSTextField* textFailNum;
    IBOutlet NSTextField* textAllNum;
    IBOutlet NSTextField* textPercentage;
    IBOutlet NSTextField* textMaxResistance;
    IBOutlet NSTextField* textMinResistance;
    IBOutlet NSTextField* textShortStandard;
    IBOutlet NSTextField* textMaxUniformity;
    IBOutlet NSTextField* textUResult;
    IBOutlet NSTextField* textFieldTime;
}

@property(nonatomic,strong)IBOutlet JNWAnimatableWindow *JNWindow;
@property(nonatomic,strong)ORSSerialPortManager* serialPortManager;

@end
