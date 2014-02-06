//
//  Socket.h
//  Read function description comments in .m
//
//  Created by Tom Furman on 5/3/11.
//  Copyright 2011 Agilent Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SOCKETIO_ERROR_DOMAIN @"SOCKETIO"
#define SOCKETIO_ERROR_CODE_UNABLE_TO_CREATE_SOCKET 1
#define SOCKETIO_ERROR_CODE_UNABLE_TO_CONNECT 2
#define SOCKETIO_ERROR_CODE_ERROR_WRITING 3
#define SOCKETIO_ERROR_CODE_ERROR_READING 4

@interface SocketIO: NSObject {
    int sockd;      /* socket file descriptor - holds "reference" to our socket session */
}

// public
- (id)init;     

- (BOOL)openWithAddress:(NSString*)address port:(int)port timeout:(int)timeout error:(NSError**)error;  
- (BOOL)closeWithError:(NSError**)error;

- (BOOL)writeBuffer:(char*)buffer size:(int)size timeout:(int)timeout error:(NSError**)error;
- (BOOL)writeString:(NSString*)string timeout:(int)timeout error:(NSError**)error;

- (BOOL)readBuffer:(char*)buffer sizeToRead:(int)sizeToRead sizeRead:(int*)sizeRead timeout:(int)timeout error:(NSError**)error;
- (BOOL)readLine:(NSString**)response newLineToken:(NSString *)newLineToken timeout:(int)timeout error:(NSError**)error;

// private
- (BOOL)waitForRecvSignal:(int)timeout error:(NSError**)error;
- (BOOL)waitForSendSignal:(int)timeout error:(NSError**)error;
- (BOOL)waitForConnectSignal:(int)timeout error:(NSError**)error;
- (long)getCurrentTime;

@end
