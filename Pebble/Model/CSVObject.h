//
//  CSVObject.h
//  Plum
//
//  Created by tpk on 14-11-11.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"

@interface CSVObject : NSObject{
    NSString *m_CSVString;
    NSString *m_CSVName;
    NSString* csvPath;
    NSString* logPath;
}

#ifndef ALLCSV
+ (CSVObject *)sharedManager;
#endif

- (BOOL)createLOG:(NSString*)logName ;
- (BOOL)createCSV:(NSString*)csvName withFront:(NSString*)csvTitle;
- (NSString*)getCSVString;
- (NSString*)getCSVPath;
- (void)setCSVString:(NSString*)str;
- (void)addString:(NSString*)str;
- (void)replaceString:(NSString*)oldstr withNewString:(NSString*)newstr;
- (void)writeToLog;
- (void)writeToCSV;

@end
