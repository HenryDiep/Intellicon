//
//  AiOS_IO.h
//  Read function description comments in .m
//
//  Created by Tom Furman on 5/3/11.
//  Copyright 2011 Agilent Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"

/* low level IO type to use, possible to add addtional ones */
typedef enum {
    IO_TYPE_SOCKETS,
    IO_TYPE_NOTSET
} IOType;

#define IO_ERROR_DOMAIN @"AiOS_IO"
#define IO_ERROR_CODE_BADFORMAT 1

/* macro to get the size of an array on the stack */
#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0])) 

@interface AiOS_IO : NSObject {
    SocketIO *socketIO;     /* low level io layer */
    int connectTimeout;
    int scanTimeout;
    int printTimeout;
    BOOL isConnected;
    IOType ioType;
    NSString* newLineToken;     /* character(s) used by instrument to specify end of command (\n) */
    int deviceClearPort;        /* socket port to use when wanting to send a device clear to the instrument */
    NSString *addressConnected; /* the address used to connect to the instrument, used when connecting to do a device clear */
}

@property (nonatomic) int connectTimeout;
@property (nonatomic) int scanTimeout;
@property (nonatomic) int printTimeout;
@property (nonatomic) BOOL isConnected;
@property (nonatomic, retain) NSString *newLineToken;


- (id)init;
- (BOOL)openWithAddress:(NSString *)address port:(int)port error:(NSError **)error;
- (BOOL)closeWithError:(NSError **)error;
- (BOOL)queryDeviceClearPort:(NSString *)query error:(NSError **)error;

- (BOOL)printBuffer:(char*)buffer size:(int)size error:(NSError **)error;
- (BOOL)print:(NSString*)message error:(NSError **)error;
- (BOOL)print:(NSString*)message appendNewLine:(BOOL)appendNewLine error:(NSError **)error;


- (BOOL)scanBuffer:(char*)buffer sizeToRead:(int)sizeToRead sizeRead:(int *)sizeRead error:(NSError **)error;
- (BOOL)scan:(NSString**)response error:(NSError**)error;
- (BOOL)scan:(NSString**)response trimNewLine:(BOOL)trimNewLine error:(NSError **)error;
- (BOOL)scanBinaryDefiniteSizeBlocks:(int)blocksCount buffers:(char**)buffers blocksRead:(int *)blocksRead buffersReadSize:(int *)buffersReadSize error:(NSError**)error;

- (BOOL)query:(NSString*)query response:(NSString **)response error:(NSError **)error;

- (BOOL)deviceClearWithError:(NSError **)error;

@end
