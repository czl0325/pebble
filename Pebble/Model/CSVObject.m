//
//  CSVObject.m
//  Plum
//
//  Created by tpk on 14-11-11.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "CSVObject.h"
#import "NSTools.h"

@implementation CSVObject

#ifndef ALLCSV
static CSVObject *_sharedManager = nil;

+(CSVObject *)sharedManager {
    @synchronized( [CSVObject class] ){
        if(!_sharedManager)
            _sharedManager = [[self alloc] init];
        return _sharedManager;
    }
    return nil;
}

+(id)alloc {
    @synchronized ([CSVObject class]){
        NSAssert(_sharedManager == nil,
                 @"Attempted to allocated a second instance");
        _sharedManager = [super alloc];
        return _sharedManager;
    }
    return nil;
}
#endif

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (BOOL)createLOG:(NSString*)logName {
    if (!m_CSVString) {
        m_CSVString = @"";
    }
    m_CSVName = logName;
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
    path = [path stringByAppendingPathComponent:@"log"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    logPath = [path stringByAppendingPathComponent:m_CSVName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:csvPath]) {
        [[NSFileManager defaultManager] createFileAtPath:csvPath contents:nil attributes:nil];
        return YES;
    }
    return NO;
}

- (BOOL)createCSV:(NSString*)csvName withFront:(NSString*)csvTitle {
    if (!m_CSVString) {
        m_CSVString = @"";
    }
    m_CSVName = csvName;
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
    csvPath = [path stringByAppendingPathComponent:m_CSVName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:csvPath]) {
        [[NSFileManager defaultManager] createFileAtPath:csvPath contents:[csvTitle dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        return YES;
    }
    return NO;
}

- (NSString*)getCSVString {
    return m_CSVString;
}

- (NSString*)getCSVPath {
    return csvPath;
}

- (void)setCSVString:(NSString*)str {
    m_CSVString = str;
}

- (void)addString:(NSString*)str {
    m_CSVString = [m_CSVString stringByAppendingString:str];
}

- (void)replaceString:(NSString*)oldstr withNewString:(NSString*)newstr {
    m_CSVString = [m_CSVString stringByReplacingOccurrencesOfString:oldstr withString:newstr];
}

- (void)writeToLog {
    if (![[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
    }
    [m_CSVString writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)writeToCSV {
    if (![[NSFileManager defaultManager] fileExistsAtPath:csvPath]) {
        [[NSFileManager defaultManager] createFileAtPath:csvPath contents:nil attributes:nil];
    }
    FILE* file = fopen([csvPath cStringUsingEncoding:NSASCIIStringEncoding], "at+");
    fputs([m_CSVString cStringUsingEncoding:NSASCIIStringEncoding], file);
    fclose(file);
}

@end
