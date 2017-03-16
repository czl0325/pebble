//
//  RootWindowController.m
//  Margaux
//
//  Created by tpk on 15-1-13.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import "RootWindowController.h"

#define ANIM_GROUP          @"animationDismiss"

@interface RootWindowController ()

@end

@implementation RootWindowController

@synthesize JNWindow;
@synthesize serialPortManager;

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        xArray = [NSMutableArray new];
        yArray = [NSMutableArray new];
        xShort = [NSMutableArray new];
        yShort = [NSMutableArray new];
        arrayResData = [NSMutableArray new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    usbHid = [[UsbHID alloc]initWithVID:0x1391 withPID:0x2111];
    usbHid.delegate = self;
    
#ifdef ALLCSV
    strLOG = @"";
    strCSV = @"";
    logObject = [[CSVObject alloc]init];
    csvObject = [[CSVObject alloc]init];
#endif
    
    serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [serialPortManager addObserver:self forKeyPath:@"availablePorts" options:options context:NULL];
#ifdef TEST
    NSLog(@"%@",serialPortManager.availablePorts);
#endif
    
    [DJProgressHUD showStatus:@"Loading..." FromView:self.window.contentView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //打开串口
        for (ORSSerialPort* port in self.serialPortManager.availablePorts) {
            if ([port.name hasPrefix:@"usbserial-"]) {
                if (multimeterPort) {
                    [multimeterPort close];
                    multimeterPort.delegate = nil;
                }
                multimeterPort = port;
                multimeterPort.delegate = self;
                if ([multimeterPort open]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageViewComm.image = [NSImage imageNamed:@"Connect.png"];
                    });
                }
            }
        }
#ifdef ALLCSV
#else
        if (![self createCSVFile]) {
            int allcount = 0;
            int passcount = 0;
            int failcount = 0;
            NSString* csvString = [NSString stringWithContentsOfFile:[[CSVObject sharedManager] getCSVPath] encoding:NSUTF8StringEncoding error:nil];
            NSArray* arrayCSV = [csvString componentsSeparatedByString:@"\n"];
            for (int i=0; i<arrayCSV.count; i++) {
                NSString* str = [arrayCSV objectAtIndex:i];
                NSRange range = [str rangeOfString:@"PASS"];
                if (range.length>0) {
                    passcount+=1;
                    allcount+=1;
                } else {
                    range = [str rangeOfString:@"FAIL"];
                    if (range.length>0) {
                        failcount+=1;
                        allcount+=1;
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                textAllNum.stringValue = [NSString stringWithFormat:@"%d",allcount];
                textPassNum.stringValue = [NSString stringWithFormat:@"%d",passcount];
                textFailNum.stringValue = [NSString stringWithFormat:@"%d",failcount];
            });
        }
#endif
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.plist"]]) {
            [[NSFileManager defaultManager] createFileAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.plist"] contents:nil attributes:nil];
            NSDictionary* dic = [NSDictionary dictionaryWithObjectsAndKeys:@(90), @"maxres", @(25), @"minres", @(3.0), @"minshort", @(0.1), @"umax", nil];
            [dic writeToFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.plist"] atomically:YES];
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.plist"]]) {
            NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"config.plist"]];
            m_fMaxRes = [[dic objectForKey:@"maxres"]floatValue];
            m_fMinRes = [[dic objectForKey:@"minres"]floatValue];
            m_fMinShort = [[dic objectForKey:@"minshort"]floatValue];
            m_fUMax = [[dic objectForKey:@"umax"]floatValue];
            m_uRange = [dic objectForKey:@"urange"];
            dispatch_async(dispatch_get_main_queue(), ^{
                textMaxResistance.stringValue=[NSString stringWithFormat:@"%.1fk",m_fMaxRes];
                textMinResistance.stringValue=[NSString stringWithFormat:@"%.1fk",m_fMinRes];
                textShortStandard.stringValue=[NSString stringWithFormat:@"%.1fv",m_fMinShort];
                textMaxUniformity.stringValue=[NSString stringWithFormat:@"%.2f%%",m_fUMax*100];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [DJProgressHUD dismiss];
        });
    });
    
    backView.backgroundColor = [NSColor cyanColor];
    m_Grain = 0;
    isUP = YES;
    isRunAlert = NO;
    backView.grain = m_Grain;
    [backView setWantsLayer:YES];
    [textViewResult setCanEdit:YES];
    
    [progressBar setMaxValue:100];
    [progressBar setDoubleValue:0];
    [progressBar setProgressText: @"0%"];
    [progressBar display];
    
    [imageViewUsb setToolTip:@"Usb Disconnected!"];
    [imageViewComm setToolTip:@"Comm Disconnected!"];
    textFieldSN.mydelegate = self;
    [textViewResult setMaxSize:CGSizeMake(FLT_MAX, FLT_MAX)];
    [textViewResult setHorizontallyResizable:YES];
    [[textViewResult textContainer] setWidthTracksTextView:NO];
    [[textViewResult textContainer] setContainerSize:CGSizeMake(FLT_MAX, FLT_MAX)];
    imageBackView.alphaValue = 0.4f;
    [self.window.contentView setWantsLayer:YES];
    
    isWaitData = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        while (true) {
            sleep(1);
            if (isWaitData) {
                if ([[NSDate date] timeIntervalSinceDate:dateForStartWait]>10) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //回调或者说是通知主线程刷新，
                        isWaitData = NO;
                        [btStart.cell setImage:[NSImage imageNamed:@"start.png"]];
                        textViewResult.string = @"";
                        NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:@"No Recv Data!"];
                        [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange(0,[mstring length])];
                        [textViewResult insertText:mstring];
                        m_nProgress = 0.0;
                        [progressBar setDoubleValue:m_nProgress];
                        [progressBar setProgressText: @"0%"];
                        [progressBar display];
#ifdef ALLCSV
                        strLOG = @"";
                        strCSV = @"";
#else
                        [[CSVObject sharedManager] setCSVString:@""];
#endif
                        [self stopTestTimer];
                        m_fTimeStamp = 0.0;
                        textFieldTime.stringValue = @"0.0 sec";
                        
                        char* send1 = "*cls\n";
                        NSData *data = [NSData dataWithBytes:send1 length:strlen(send1)];
                        [multimeterPort sendData:data];
                        
                        shakeWindow(self.window);
                    });
                }
            }
        }
    });
}

- (BOOL)windowShouldClose:(id)sender {
    [JNWindow orderOutWithDuration:0.6 timing:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] animations:^(CALayer *layer) {
        layer.transform =  CATransform3DMakeTranslation(700, 0.0f, 0.0f);
        layer.opacity = 0.f;
    }];
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)createCSVFile {
    NSString* title = @"Pebble Test v1.0\nSerialNumber,OverAllResult,uMax,";
    for (int i=0; i<ALLPIN; i++) {
        title=[title stringByAppendingString:[NSString stringWithFormat:@"x%d,",i+1]];
    }
    for (int i=0; i<ALLPIN; i++) {
        title=[title stringByAppendingString:[NSString stringWithFormat:@"y%d,",i+1]];
    }
    for (int i=0; i<ALLPIN; i++) {
        title=[title stringByAppendingString:[NSString stringWithFormat:@"u%d,",i+1]];
    }
    title = [title stringByAppendingString:@"\n"];
    return [[CSVObject sharedManager] createCSV:[NSString stringWithFormat:@"%@.csv",formatDateToString([NSDate date])] withFront:title];
}


#pragma mark 发送读取万用表的数据
- (void)initMultimeter {
    char* send1 = "*cls\n";
    NSData *data = [NSData dataWithBytes:send1 length:strlen(send1)];
    [multimeterPort sendData:data];
    char* send3 = "configure:fresistance\n";
    data = [NSData dataWithBytes:send3 length:strlen(send3)];
    [multimeterPort sendData:data];
}

- (void)getManyData {
    char* send6 = "read?\n";
    NSData* data = [NSData dataWithBytes:send6 length:strlen(send6)];
    [multimeterPort sendData:data];
}

- (void)changeBackView {
    if (m_Grain>=10) {
        isUP = NO;
    } else if (m_Grain<=1) {
        isUP = YES;
    }
    if (isUP) {
        m_Grain+=1;
    } else {
        m_Grain-=1;
    }
    [backView setGrain:m_Grain];
}

- (void)acceptKeyCode:(KeyBoardTextField*)keyboardTextField keyCode:(unsigned short)keyCode {
    if (keyboardTextField==textFieldSN) {
        if (!isRunAlert) {
            if (keyCode==76||keyCode==36) {
                [self clickStart:nil];
            }
        }
    }
}

- (void)dismissAlertView {
    isRunAlert = NO;
}

- (IBAction)clickStart:(id)sender {
    if (m_fMinRes>=m_fMaxRes) {
        isRunAlert = YES;
        if(NSRunAlertPanel(@"ERROR", @"Min Resistance Is Large Than Max Resistance!", @"OK", nil, nil)==1) {
            [self performSelector:@selector(dismissAlertView) withObject:nil afterDelay:0.3];
        }
        return ;
    }
    if (textFieldSN.stringValue.length==0) {
        isRunAlert = YES;
        if(NSRunAlertPanel(@"ERROR", @"SN Number Empty!", @"OK", nil, nil)==1) {
            [self performSelector:@selector(dismissAlertView) withObject:nil afterDelay:0.3];
        }
        return ;
    }
//    scrollTextView = [[ScrollingTextView alloc]initWithFrame:NSMakeRect(0, backView.height/2-100, backView.width, 200)];
//    [scrollTextView setWantsLayer:YES];
//    [scrollTextView setBackgroundColor:[NSColor clearColor]];
//    [scrollTextView setDirection:NSLEFTTORIGHT];
//    [scrollTextView setString:@"Testing..."];
//    [backView addSubview:scrollTextView];
    
#ifdef ALLCSV
    strLOG = [NSString stringWithFormat:@"SN:%@\n\n",textFieldSN.stringValue];
    strCSV = @"";
#endif
    testPIN = 1;
    axis = 1;
    m_nProgress = 0;
    //[btStart setEnabled:NO];
    dateForStartWait = [NSDate date];
    isWaitData = !isWaitData;
    allPass = YES;
    xPass = YES;
    yPass = YES;
    uPass = YES;
    shortPass = YES;
    [xArray removeAllObjects];
    [yArray removeAllObjects];
    [xShort removeAllObjects];
    [yShort removeAllObjects];
    frontGap = 0;
    backGap = 0;
    uMax = 0;
#ifndef ALLCSV
    [[CSVObject sharedManager] setCSVString:@""];
#endif
    strErrorCode = @"";
    dateStart = [NSDate date];
    timeStart = CFAbsoluteTimeGetCurrent();
    multimeterCommString = @"";
    m_fTimeStamp = 0.0f;
    textFieldTime.stringValue = @"0.0 sec";
    textPassOrFail.stringValue = @"Null";
    textPassOrFail.textColor = TEXTFAILCOLOR;
    [self stopTestTimer];
    if (isWaitData) {
        textViewResult.string = @"";
        [btStart.cell setImage:[NSImage imageNamed:@"stop.png"]];
        timerTest = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(startTestTimer) userInfo:nil repeats:YES];
        
        [self initMultimeter];
        
        NSString* textstring = [NSString stringWithFormat:@"************Pebble Test V1.0\n************SN : %@\n************Start Front Resistance Test At %@\n",textFieldSN.stringValue,formatDateToStringALL(dateStart)];
        NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:textstring];
        [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0,[mstring length])];
        [textViewResult insertText:mstring];
        
#ifdef ALLCSV
        strLOG = [strLOG stringByAppendingString:@"*********,*********,X Test,*********,*********\n"];
        strCSV = [strCSV stringByAppendingString:[NSString stringWithFormat:@"%@,OverAllResult,uMax,",textFieldSN.stringValue]];
#else
        [[CSVObject sharedManager] addString:[NSString stringWithFormat:@"%@,OverAllResult,uMax,",textFieldSN.stringValue]];
#endif
    } else {
        [btStart.cell setImage:[NSImage imageNamed:@"start.png"]];
        
        char* send1 = "*cls\n";
        NSData *data = [NSData dataWithBytes:send1 length:strlen(send1)];
        [multimeterPort sendData:data];
    }
    [arrayResData removeAllObjects];
    
    char sendbuff[2];
    memset(sendbuff,0x00,sizeof(sendbuff));
    sendbuff[0] = 0xac;
    [usbHid senddata:sendbuff];
}


- (void)dismiss2 {
    if (scrollTextView) {
        scrollTextView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        CGPoint p = scrollTextView.layer.position;
        CGSize s = scrollTextView.layer.bounds.size;
        scrollTextView.layer.position = CGPointMake(p.x+s.width/2.0, p.y+s.height/2.0);
        CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
        animation.duration = 3.0;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.delegate = self;
        NSMutableArray* values = [NSMutableArray new];
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1.0)]];
        [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(4.0, 4.0, 1.0)]];
        animation.values = values;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
        [scrollTextView.layer addAnimation:animation forKey:nil];
    }
}

- (void)dismissScrollTextView {
    if (scrollTextView) {
        scrollTextView.layer.anchorPoint = CGPointMake(0.5, 0.5);
        CGPoint p = scrollTextView.layer.position;
        CGSize s = scrollTextView.layer.bounds.size;
        scrollTextView.layer.position = CGPointMake(p.x+s.width/2.0, p.y+s.height/2.0);
        //在层上做旋转动画
        CAAnimation* myAnimationScale           = myScale(@4, @1, 2, 1);
        CAAnimation* myAnimationOpacity         = opacityTimes_Animation(1,2);
        //设置组合动画
        CAAnimationGroup* m_pGroupAnimation     = [CAAnimationGroup animation];
        m_pGroupAnimation.delegate              = self;
        m_pGroupAnimation.removedOnCompletion   = NO;
        m_pGroupAnimation.duration              = 2;
        m_pGroupAnimation.timingFunction        = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        m_pGroupAnimation.repeatCount           = 1;//FLT_MAX;  //"forever";
        m_pGroupAnimation.fillMode              = kCAFillModeForwards;
        m_pGroupAnimation.animations            = [NSArray arrayWithObjects:myAnimationScale, myAnimationOpacity, nil];
        //对视图自身的层添加组动画
        [scrollTextView.layer addAnimation:m_pGroupAnimation forKey:ANIM_GROUP];
    }
}

#pragma mark Usbhid的代理
- (void)usbhidDidRecvData:(uint8_t*)recvData length:(CFIndex)reportLength {
#ifdef TEST
    NSLog(@"%02x,%02x,%02x,%02x",recvData[0],recvData[1],recvData[2],recvData[3]);
    //NSString* str11 = [NSString stringWithFormat:@"usb接收:%02x,%02x,%02x,%02x\n",recvData[0],recvData[1],recvData[2],recvData[3]];
    //writeTestData(str11);
#endif
    if (!isWaitData) {
        return;
    }
    dateForStartWait = [NSDate date];
    [textViewResult setSelectedRange:NSMakeRange(textViewResult.textStorage.string.length, 0)];
    if (recvData[0]==0xac) {
        char outbuffer[4] ;
        memset(outbuffer, 0x00, sizeof(outbuffer));
        outbuffer[0] = 0xa1;
        outbuffer[1] = testPIN;
        outbuffer[2] = axis;
        outbuffer[3] = 0x01;
        [usbHid senddata:outbuffer];
    } else if (recvData[0]==0xa1&&recvData[3]==1) {
        [self performSelector:@selector(getManyData) withObject:nil afterDelay:0.0];
    } else if (recvData[0]==0xa1&&recvData[3]==0) {
        testPIN++;
        if (testPIN>ALLPIN&&axis==1) {
            testPIN=1;
            axis=2;
            NSDate* date = [NSDate date];
            NSString* str = [NSString stringWithFormat:@"************Finish Front Resistance Test At %@\n************Result: %@\n",formatDateToStringALL(date),xPass?@"Pass":@"Fail"];
            NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
            [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [mstring length])];
            if (xPass) {
                [mstring addAttribute:NSForegroundColorAttributeName value:PASSCOLOR range:NSMakeRange([mstring length]-5, 5)];
            } else {
                [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange([mstring length]-5, 5)];
            }
            [textViewResult insertText:mstring];
            
            date = [NSDate date];
            str = [NSString stringWithFormat:@"************Start Back Resistance Test At %@\n",formatDateToStringALL(date)];
            NSMutableAttributedString* attstring = [[NSMutableAttributedString alloc]initWithString:str];
            [attstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [attstring length])];
            [textViewResult insertText:attstring];
#ifdef ALLCSV
            strLOG = [strLOG stringByAppendingFormat:@"\n*********,*********,Y Test,*********,*********\n"];
#endif
        } else if (testPIN>ALLPIN&&axis==2) {
            NSDate* date = [NSDate date];
            NSString* str = [NSString stringWithFormat:@"************Finish Back Resistance Test At %@\n************Result: %@\n",formatDateToStringALL(date),yPass?@"Pass":@"Fail"];
            NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
            [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [mstring length])];
            if (yPass) {
                [mstring addAttribute:NSForegroundColorAttributeName value:PASSCOLOR range:NSMakeRange([mstring length]-5, 5)];
            } else {
                [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange([mstring length]-5, 5)];
            }
            [textViewResult insertText:mstring];
            
            [self uniformityTest];
            [self maxAndMinTest];
            [self shortTest];
            return;
        }
        char outbuffer[4] ;
        memset(outbuffer, 0x00, sizeof(outbuffer));
        outbuffer[0] = 0xa1;
        outbuffer[1] = testPIN;
        outbuffer[2] = axis;
        outbuffer[3] = 0x01;
        [usbHid senddata:outbuffer];
    } else if (recvData[0]==0xaa) {
        for (int i=0; i<23; i++) {
            [xShort addObject:@(BYTETOWORD(recvData[2+i*2], recvData[3+i*2]))];
        }
        NSArray* xText = [self getShortArray:YES];
        if (xShort.count>=xText.count) {
            for (int i=0; i<xText.count-1; i++) {
                float number = SHORTFORMULA([[xShort objectAtIndex:i]floatValue]);
                NSString* str = [NSString stringWithFormat:@"%@-%@=%.3fv",[xText objectAtIndex:i],[xText objectAtIndex:i+1],number];
                str = [str stringByAppendingString:@"   "];
                if ((i+1)%5==0) {
                    str = [str stringByAppendingString:@"\n"];
                }
                NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
                [mstring addAttribute:NSForegroundColorAttributeName value:TEXTPASSCOLOR range:NSMakeRange(0, [mstring length])];
                if (number<m_fMinShort) {
                    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange(0, [mstring length])];
                    shortPass = NO;
                    //allPass = NO;
                }
                [textViewResult insertText:mstring];
            }
            [textViewResult insertText:@"\n"];
        }
//        char outbuffer[2] ;
//        memset(outbuffer, 0x00, sizeof(outbuffer));
//        outbuffer[0] = 0xa2;
//        outbuffer[1] = 0xaa;
//        [usbHid senddata:outbuffer];
    } else if (recvData[0]==0xbb) {
        for (int i=0; i<23; i++) {
            [yShort addObject:@(BYTETOWORD(recvData[2+i*2], recvData[3+i*2]))];
        }
        NSArray* yText = [self getShortArray:NO];
        if (yShort.count>=yText.count) {
            for (int i=0; i<yText.count-1; i++) {
                float number = SHORTFORMULA([[yShort objectAtIndex:i]floatValue]);
                NSString* str = [NSString stringWithFormat:@"%@-%@=%.3fv",[yText objectAtIndex:i],[yText objectAtIndex:i+1],number];
                str = [str stringByAppendingString:@"   "];
                if ((i+1)%5==0) {
                    str = [str stringByAppendingString:@"\n"];
                }
                NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
                [mstring addAttribute:NSForegroundColorAttributeName value:TEXTPASSCOLOR range:NSMakeRange(0, [mstring length])];
                if (number<m_fMinShort) {
                    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange(0, [mstring length])];
                    shortPass = NO;
                    //allPass = NO;
                }
                [textViewResult insertText:mstring];
            }
            [textViewResult insertText:@"\n"];
            NSDate* date = [NSDate date];
            //NSString* str = [NSString stringWithFormat:@"************Finish Short Test At %@\n************Result: %@\n",formatDateToStringALL(date),shortPass?@"Pass":@"Fail"];
            NSString* str = [NSString stringWithFormat:@"************Finish Short Test At %@\n",formatDateToStringALL(date)];
            NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
            [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [mstring length])];
//            if (shortPass) {
//                [mstring addAttribute:NSForegroundColorAttributeName value:PASSCOLOR range:NSMakeRange([mstring length]-5, 5)];
//            } else {
//                [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange([mstring length]-5, 5)];
//            }
            [textViewResult insertText:mstring];
            
            dateEnd = [NSDate date];
            timeEnd = CFAbsoluteTimeGetCurrent();
            str = [NSString stringWithFormat:@"************Finish All Test At %@\n************All Result : %@\n",formatDateToStringALL(dateEnd),allPass?@"Pass":@"Fail"];
            mstring = [[NSMutableAttributedString alloc]initWithString:str];
            [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0,[mstring length])];
            NSRange range = [str rangeOfString:@"Pass"];
            if (range.length>0) {
                [mstring addAttribute:NSForegroundColorAttributeName value:PASSCOLOR range:range];
            } else {
                range = [str rangeOfString:@"Fail"];
                if (range.length>0) {
                    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:range];
                }
            }
            [textViewResult insertText:mstring];
            [btStart.cell setImage:[NSImage imageNamed:@"start.png"]];
            [self dismissScrollTextView];
            
            NSUserNotification *localNotify = [[NSUserNotification alloc] init];
            localNotify.title = @"Test Result";
            localNotify.informativeText = [NSString stringWithFormat:@"SN:%@\nTest Result:%@",textFieldSN.stringValue,allPass?@"Pass":@"Fail"];
            localNotify.soundName = NSUserNotificationDefaultSoundName;
            localNotify.hasActionButton = YES;
            localNotify.actionButtonTitle = @"OK";
            localNotify.otherButtonTitle = @"Cancel";
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:localNotify];
            //设置通知的代理
            [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
            
#ifdef ALLCSV
            [logObject createLOG:[NSString stringWithFormat:@"%@(%@).csv",textFieldSN.stringValue,formatDateToStringALL(dateEnd)]];
            [logObject setCSVString:strLOG];
            [logObject writeToLog];
            
            NSString* title = @"Pebble Test v1.0\nSerialNumber,OverAllResult,uMax,";
            for (int i=0; i<ALLPIN; i++) {
                title=[title stringByAppendingString:[NSString stringWithFormat:@"x%d,",i+1]];
            }
            for (int i=0; i<ALLPIN; i++) {
                title=[title stringByAppendingString:[NSString stringWithFormat:@"y%d,",i+1]];
            }
            for (int i=0; i<ALLPIN; i++) {
                title=[title stringByAppendingString:[NSString stringWithFormat:@"u%d,",i+1]];
            }
            title = [title stringByAppendingString:@"\n"];
            [csvObject createCSV:[NSString stringWithFormat:@"%@.csv",formatDateToString([NSDate date])] withFront:title];
            strCSV = [strCSV stringByReplacingOccurrencesOfString:@"uMax" withString:[NSString stringWithFormat:@"%.2f%%",uMax*100]];
            strCSV = [strCSV stringByReplacingOccurrencesOfString:@"OverAllResult" withString:allPass?@"PASS":@"FAIL"];
            strCSV = [strCSV stringByAppendingString:@"\n"];
            [csvObject setCSVString:strCSV];
            [csvObject writeToCSV];
#else
            [[CSVObject sharedManager] replaceString:@"uMax" withNewString:[NSString stringWithFormat:@"%.2f%%",uMax*100]];
            [[CSVObject sharedManager] replaceString:@"OverAllResult" withNewString:allPass?@"PASS":@"FAIL"];
            [[CSVObject sharedManager] addString:@"\n"];
            
            [self writeToLog];
            [self createCSVFile];
            [[CSVObject sharedManager] writeToCSV];
#endif
            char* send1 = "*cls\n";
            NSData *data = [NSData dataWithBytes:send1 length:strlen(send1)];
            [multimeterPort sendData:data];
            
            [self changeNumberOfResult:allPass];
            textFieldSN.stringValue = @"";
            m_nProgress=100;
            [self stopTestTimer];
            textFieldTime.stringValue = [NSString stringWithFormat:@"%.1f sec",timeEnd-timeStart];
            [progressBar setDoubleValue:m_nProgress];
            [progressBar setProgressText:@"100%"];
            [progressBar display];
            isWaitData = NO;
        }
    }
}

- (void)usbhidDidMatch {
    imageViewUsb.image = [NSImage imageNamed:@"Connect.png"];
    [imageViewUsb setToolTip:@"Usb Connected!"];
}

- (void)usbhidDidRemove {
    imageViewUsb.image = [NSImage imageNamed:@"Disconnect.png"];
    [imageViewUsb setToolTip:@"Usb Disconnect!"];
}

#pragma mark 串口代理的方法
- (void)serialPortWasOpened:(ORSSerialPort *)serialPort {
    if (serialPort==multimeterPort) {
//        char* send1 = "*cls\n";
//        NSData *data = [NSData dataWithBytes:send1 length:strlen(send1)];
//        [multimeterPort sendData:data];
//        char* send3 = "configure:resistance\n";
//        data = [NSData dataWithBytes:send3 length:strlen(send3)];
//        [multimeterPort sendData:data];
    }
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort {
    
}

//串口接收到数据的代理
- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data {
    if (!isWaitData) {
        return;
    }
    NSString* recvstring = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    if (recvstring.length==0) {
        return;
    }
#ifdef TEST
    //NSString* str11 = [NSString stringWithFormat:@"comm接收:%@\n",recvstring];
    //writeTestData(str11);
#endif
    [textViewResult setSelectedRange:NSMakeRange(textViewResult.textStorage.string.length, 0)];
    if ([serialPort.name isEqualToString:multimeterPort.name]) {
        dateForStartWait = [NSDate date];
        multimeterCommString = [multimeterCommString stringByAppendingString:recvstring];
        if ([multimeterCommString hasSuffix:@"\r"]) {
            multimeterCommString = [multimeterCommString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            multimeterCommString = [multimeterCommString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            multimeterCommString = [multimeterCommString stringByReplacingOccurrencesOfString:@"^S" withString:@""];
            multimeterCommString = [multimeterCommString stringByReplacingOccurrencesOfString:@"^Q" withString:@""];
#ifdef TEST
            NSLog(@"万用表:%@",multimeterCommString);
            //NSString* str12 = [NSString stringWithFormat:@"读取的电阻:%@\n",multimeterCommString];
            //writeTestData(str12);
#endif
#ifdef C2400
            NSArray* arr1 = [multimeterCommString componentsSeparatedByString:@","];
            NSString* commString1 = [arr1 objectAtIndex:2];
            NSArray* arr = [commString1 componentsSeparatedByString:@"E"];
#else
            NSArray* arr = [multimeterCommString componentsSeparatedByString:@"E"];
#endif
            char cc[100];
            memset(cc, 0x00, sizeof(cc));
            strcpy(cc, [[arr objectAtIndex:1] cStringUsingEncoding:NSUTF8StringEncoding]);
            int n = atoi(cc);
            float nn = pow(10,n);
            float m = atof([[arr objectAtIndex:0] cStringUsingEncoding:NSUTF8StringEncoding]);
            float mm = m*nn;
            
            float resistance = mm/1000.0;
            if (resistance > 9999.0) {
                resistance = 9999.0;
            }
            [arrayResData addObject:@(resistance)];
            
            if ((resistance<=m_fMaxRes&&resistance>=m_fMinRes)||arrayResData.count>=3) {
                NSString* textstring = [NSString stringWithFormat:@"%@%d=%.3fk     ",axis==1?@"x":@"y", testPIN, resistance];
                if (testPIN<=10) {
                    textstring = [textstring stringByAppendingString:@"  "];
                }
                if (testPIN%5==0) {
                    textstring = [textstring stringByAppendingString:@"\n"];
                }
                NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:textstring];
                [mstring addAttribute:NSForegroundColorAttributeName value:TEXTPASSCOLOR range:NSMakeRange(0,[mstring length])];
                if (resistance < m_fMinRes || resistance > m_fMaxRes) {
                    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange(0,[mstring length])];
                    if (axis==1) {
                        xPass = NO;
                    } else {
                        yPass = NO;
                    }
                    allPass = NO;
                }
                [textViewResult insertText:mstring];
                if (axis==1) {
                    [xArray addObject:@(resistance)];
                } else {
                    [yArray addObject:@(resistance)];
                }
                m_nProgress++;
                [progressBar setDoubleValue:m_nProgress];
                [progressBar setProgressText:[NSString stringWithFormat:@"%d%%",m_nProgress]];
                [progressBar display];
                
#ifdef ALLCSV
                strCSV = [strCSV stringByAppendingString:[NSString stringWithFormat:@"%.3f,",resistance]];
                strLOG = [strLOG stringByAppendingString:[NSString stringWithFormat:@"%.3f,",resistance]];
                if (testPIN%5==0) {
                    strLOG = [strLOG stringByAppendingString:@"\n"];
                }
#else
                [[CSVObject sharedManager] addString:[NSString stringWithFormat:@"%.3f,",resistance]];
#endif
                
                [arrayResData removeAllObjects];
                
                char outbuffer[4] ;
                memset(outbuffer, 0x00, sizeof(outbuffer));
                outbuffer[0] = 0xa1;
                outbuffer[1] = testPIN;
                outbuffer[2] = axis;
                outbuffer[3] = 0;
                [usbHid senddata:outbuffer];
            } else {
                [self performSelector:@selector(getManyData) withObject:nil afterDelay:0.05];
            }
            multimeterCommString = @"";
        }
    }
}

//串口拔出的代理
- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort {
    
}

//串口遇到错误的代理
- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error {
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, object, keyPath);
    NSLog(@"Change dictionary: %@", change);
}

#pragma mark - NSUserNotificationCenterDelegate
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [center removeDeliveredNotification:notification];
    });
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}
#endif

#pragma mark - Notifications
#pragma mark 串口插入的通知
- (void)serialPortsWereConnected:(NSNotification *)notification {
    NSArray *connectedPorts = [[notification userInfo] objectForKey:ORSConnectedSerialPortsKey];
#ifdef TEST
    NSLog(@"Ports were connected: %@", connectedPorts);
#endif
    [self postUserNotificationForConnectedPorts:connectedPorts];
    for (ORSSerialPort* port in connectedPorts) {
        if ([port.name hasPrefix:@"usbserial-"]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (multimeterPort) {
                    [multimeterPort close];
                    multimeterPort.delegate = nil;
                }
                multimeterPort = port;
                multimeterPort.delegate = self;
                sleep(2);
                if ([multimeterPort open]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageViewComm.image = [NSImage imageNamed:@"Connect.png"];
                        [imageViewComm setToolTip:@"Comm Connected!"];
                    });
                }
            });
            break;
        }
    }
}

#pragma mark 串口拔出的通知
- (void)serialPortsWereDisconnected:(NSNotification *)notification {
    NSArray *disconnectedPorts = [[notification userInfo] objectForKey:ORSDisconnectedSerialPortsKey];
#ifdef TEST
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
#endif
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    for (ORSSerialPort* port in disconnectedPorts) {
        if ([port.name hasPrefix:@"usbserial-"]) {
            if (multimeterPort) {
                [multimeterPort close];
                multimeterPort.delegate = nil;
                multimeterPort = nil;
            }
            imageViewComm.image = [NSImage imageNamed:@"Disconnect.png"];
            [imageViewComm setToolTip:@"Comm Disconnected!"];
            break;
        }
    }
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter"))
        return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts) {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter"))
        return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts) {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
        NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (scrollTextView) {
        [scrollTextView removeFromSuperview];
        scrollTextView = nil;
    }
}

#pragma mark 测试结束后的操作
- (void)changeNumberOfResult:(BOOL)isPass {
    int nAll = [textAllNum.stringValue intValue];
    int nPass = [textPassNum.stringValue intValue];
    int nFail = [textFailNum.stringValue intValue];
    nAll+=1;
    textAllNum.stringValue = [NSString stringWithFormat:@"%d",nAll];
    NSString* uStr = @"";
    if (uMax == 0) {
        uStr = @"U1";
    } else {
        for (int i=0; i<m_uRange.count-1; i++) {
            if (uMax>[[m_uRange objectAtIndex:i]floatValue]&&uMax<=[[m_uRange objectAtIndex:i+1]floatValue]) {
                uStr = [NSString stringWithFormat:@"U%d",i+1];
                break;
            }
        }
    }
    if (isPass) {
        nPass+=1;
        textPassNum.stringValue = [NSString stringWithFormat:@"%d",nPass];
        NSString* mystr = [NSString stringWithFormat:@"PASS (%@)",uStr];
        textPassOrFail.stringValue = mystr;
        textPassOrFail.textColor = PASSCOLOR;
    } else {
        nFail+=1;
        textFailNum.stringValue = [NSString stringWithFormat:@"%d",nFail];
        NSString* mystr = [NSString stringWithFormat:@"FAIL (%@)",uStr];
        textPassOrFail.stringValue = mystr;
        textPassOrFail.textColor = TEXTFAILCOLOR;
    }
    float percentage = nPass/(float)nAll;
    textPercentage.stringValue = [NSString stringWithFormat:@"%.2f%%",percentage*100];
}

#pragma mark 写入LOG
- (void)writeToLog {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    NSString* path = [documentDir stringByAppendingPathComponent:@"Pebble"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    path = [path stringByAppendingPathComponent:formatDateToString([NSDate date])];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString* logPath = [path stringByAppendingPathComponent:@"Log"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:logPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    logPath = [logPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.rtf",textFieldSN.stringValue]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
    }
    NSData * data = [textViewResult.textStorage dataFromRange:NSMakeRange(0, textViewResult.textStorage.length) documentAttributes:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} error:nil];
    [data writeToFile:logPath atomically:YES];
}

- (void)uniformityTest {
    NSDate* date = [NSDate date];
    NSString* str = [NSString stringWithFormat:@"************Start Uniformity Test At %@\n",formatDateToStringALL(date)];
    NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [mstring length])];
    [textViewResult insertText:mstring];
#ifdef ALLCSV
    strLOG = [strLOG stringByAppendingFormat:@"\n*********,*********,U Test,*********,*********\n"];
#endif
    
    testPIN=1;
    uMax = 0.0f;
    for (int i=0; i<ALLPIN; i++) {
        float up = abs([[xArray objectAtIndex:i] floatValue]-[[yArray objectAtIndex:i] floatValue]);
        float down = [[xArray objectAtIndex:i] floatValue]+[[yArray objectAtIndex:i] floatValue];
        str = [NSString stringWithFormat:@"u%d=%.3f     ",testPIN,up/down];
        if (testPIN<=10) {
            str = [str stringByAppendingString:@"  "];
        }
        if (testPIN%5==0) {
            str = [str stringByAppendingString:@"\n"];
        }
        if (up/down>uMax) {
            uMax = up/down;
        }
        mstring = [[NSMutableAttributedString alloc]initWithString:str];
        [mstring addAttribute:NSForegroundColorAttributeName value:TEXTPASSCOLOR range:NSMakeRange(0, [mstring length])];
        if ((up/down)>m_fUMax) {
            [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange(0, [mstring length])];
            uPass = NO;
            allPass = NO;
        }
        [textViewResult insertText:mstring];
#ifdef ALLCSV
        strLOG = [strLOG stringByAppendingString:[NSString stringWithFormat:@"%.2f%%,",up/down*100]];
        if (testPIN%5==0) {
            strLOG = [strLOG stringByAppendingString:@"\n"];
        }
        strCSV = [strCSV stringByAppendingString:[NSString stringWithFormat:@"%.2f%%,",up/down*100]];
#else
        [[CSVObject sharedManager] addString:[NSString stringWithFormat:@"%.2f%%,",up/down*100]];
#endif
        testPIN++;
    }
    textUResult.stringValue = [NSString stringWithFormat:@"%.2f%%",uMax*100];
    
    date = [NSDate date];
    str = [NSString stringWithFormat:@"************Finish Uniformity Test At %@\n************Result: %@\n",formatDateToStringALL(date),uPass?@"Pass":@"Fail"];
    mstring = [[NSMutableAttributedString alloc]initWithString:str];
    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [mstring length])];
    if (uPass) {
        [mstring addAttribute:NSForegroundColorAttributeName value:PASSCOLOR range:NSMakeRange([mstring length]-5, 5)];
    } else {
        [mstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange([mstring length]-5, 5)];
    }
    [textViewResult insertText:mstring];
}

- (void)maxAndMinTest {
    float xMax = 0.0f;
    float xMin = 10000.0f;
    for (int i=0; i<ALLPIN; i++) {
        if ([[xArray objectAtIndex:i] floatValue]>xMax) {
            xMax=[[xArray objectAtIndex:i] floatValue];
        }
        if ([[xArray objectAtIndex:i] floatValue]<xMin) {
            xMin=[[xArray objectAtIndex:i] floatValue];
        }
    }
    frontGap = (xMax-xMin)/(xMax+xMin);
    float yMax = 0.0f;
    float yMin = 10000.0f;
    for (int i=0; i<ALLPIN; i++) {
        if ([[yArray objectAtIndex:i] floatValue]>yMax) {
            yMax=[[yArray objectAtIndex:i] floatValue];
        }
        if ([[yArray objectAtIndex:i] floatValue]<yMin) {
            yMin=[[yArray objectAtIndex:i] floatValue];
        }
    }
    backGap = (yMax-yMin)/(yMax+yMin);
    
    NSString *str = [NSString stringWithFormat:@"************MAX Uniformity=%.3f%%\n",uMax*100];
    NSMutableAttributedString* attstring = [[NSMutableAttributedString alloc]initWithString:str];
    [attstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [attstring length])];
    NSString* changeString = [attstring string];
    NSUInteger position = 0;
    for (NSUInteger i=0; i<[changeString length]; i++) {
        char c = [changeString characterAtIndex:i];
        if (c == '=') {
            position = i+1;
            break;
        }
    }
    if (uMax<=0.025) {
        [attstring addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:0.0 green:100.0/255.0 blue:0.0 alpha:1.0] range:NSMakeRange(position, [attstring length]-position)];
    } else if (uMax>0.025&&uMax<=0.05) {
        [attstring addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:NSMakeRange(position, [attstring length]-position)];
    } else if (uMax>0.05) {
        [attstring addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(position, [attstring length]-position)];
    }
    [textViewResult insertText:attstring];
    
    [attstring removeAttribute:NSFontAttributeName range:NSMakeRange(0, [attstring length])];
    
    str = [NSString stringWithFormat:@"************MAX Uniformity of Front=%.3f%%\n************MAX Uniformity of Back=%.3f%%\n",frontGap*100,backGap*100];
    attstring = [[NSMutableAttributedString alloc]initWithString:str];
    [attstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [attstring length])];
//    if (xPass&&yPass&&uPass) {
//        [attstring addAttribute:NSForegroundColorAttributeName value:TEXTPASSCOLOR range:NSMakeRange([attstring length]-5, 5)];
//    } else {
//        [attstring addAttribute:NSForegroundColorAttributeName value:TEXTFAILCOLOR range:NSMakeRange([attstring length]-5, 5)];
//    }
    [textViewResult insertText:attstring];
    
    if (!xPass) {
        attstring = [[NSMutableAttributedString alloc]initWithString:@"************Fail in Front Resistance test,errCode:1\n"];
        [attstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [attstring length])];
        [textViewResult insertText:attstring];
    }
    if (!yPass) {
        attstring = [[NSMutableAttributedString alloc]initWithString:@"************Fail in Back Resistance test,errCode:2\n"];
        [attstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [attstring length])];
        [textViewResult insertText:attstring];
    }
    if (!uPass) {
        attstring = [[NSMutableAttributedString alloc]initWithString:@"************Fail in Uniformity Test,errCode:3\n"];
        [attstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [attstring length])];
        [textViewResult insertText:attstring];
    }
//    [[CSVObject sharedManager] addString:[NSString stringWithFormat:@"%.3f%%,%.3f%%,%.3f%%\n",uMax*100,frontGap*100,backGap*100]];
}

- (void)shortTest {
    NSDate* date = [NSDate date];
    NSString* str = [NSString stringWithFormat:@"************Start Short Test At %@\n",formatDateToStringALL(date)];
    NSMutableAttributedString* mstring = [[NSMutableAttributedString alloc]initWithString:str];
    [mstring addAttribute:NSForegroundColorAttributeName value:TEXTCOLOR range:NSMakeRange(0, [mstring length])];
    [textViewResult insertText:mstring];
    char outbuffer[2] ;
    memset(outbuffer, 0x00, sizeof(outbuffer));
    outbuffer[0] = 0xa2;
    outbuffer[1] = 0xaa;
    [usbHid senddata:outbuffer];
}

- (NSArray*)getShortArray:(BOOL)isX {
    NSArray* array = nil;
    if (isX) {
        array = [NSArray arrayWithObjects:@"x37",@"x36",@"x32",@"x31",@"x27",@"x26",@"x22",@"x21",@"x23",@"x18",@"x16",@"x17",@"x11",@"x12",@"x1",@"x6",@"x7",@"x2",@"x13",@"x8",@"x3",@"x14",@"x9",@"x4",@"x15",@"x10",@"x5",@"x19",@"x20",@"x24",@"x25",@"x29",@"x30",@"x28",@"x33",@"x35",@"x34",@"x40",@"x39",@"x45",@"x44",@"x38",@"x43",nil];
    } else {
        array = [NSArray arrayWithObjects:@"y37",@"y36",@"y32",@"y31",@"y27",@"y26",@"y22",@"y21",@"y23",@"y18",@"y16",@"y17",@"y11",@"y12",@"y1",@"y6",@"y7",@"y2",@"y13",@"y8",@"y3",@"y14",@"y9",@"y4",@"y15",@"y10",@"y5",@"y19",@"y20",@"y24",@"y25",@"y29",@"y30",@"y28",@"y33",@"y35",@"y34",@"y40",@"y39",@"y45",@"y44",@"y38",@"y43",nil];
    }
    return array;
}

- (void)startTestTimer {
    m_fTimeStamp+=0.1;
    textFieldTime.stringValue = [NSString stringWithFormat:@"%.1f sec",m_fTimeStamp];
}

- (void)stopTestTimer {
    if (timerTest) {
        [timerTest invalidate];
        timerTest = nil;
    }
}

@end
