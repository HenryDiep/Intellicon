//
//  AiOS_IO.m
//  A class for doing instrument I/O communication.  It provides higher level functions applicable to instruments
//  as compared to SocketsIO .
//  It uses SocketIO as a lower communication layer.  Additional layers could be added.
//  You can open connection, print, scan, query, and close.
//
//  Created by Tom Furman on 5/3/11.
//  Copyright 2011 Agilent Technologies, Inc. All rights reserved.
//

#import "AiOS_IO.h"
#import "Error.h"

@implementation AiOS_IO

@synthesize connectTimeout, scanTimeout, printTimeout, isConnected, newLineToken;

/******************************************************
 initalize class 
 
 returns: self reference
 *******************************************************/
- (id)init {
    connectTimeout = 5000;
    scanTimeout = 5000;
    printTimeout = 5000;
    ioType = IO_TYPE_SOCKETS;
    isConnected = NO;
    newLineToken = @"\n";
    deviceClearPort = -1;
       
    [super init];
    
    return self;
}


- (void)dealloc
{
    [newLineToken release];
    [addressConnected release];
    [socketIO release];
    [super dealloc];
}
            
        

/******************************************************
 Attempt to open connection to the specific address
 
 address: ip or hostname
 port: port number
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)openWithAddress:(NSString *)address port:(int)port error:(NSError **)error {
    BOOL success;

    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                socketIO = [[SocketIO alloc] init]; /* create an instance of sockets */
                
                success = [socketIO openWithAddress:address port:port timeout:connectTimeout error:error];
                if (success == NO)
                    return NO;
                
                isConnected = YES;
                addressConnected = [address copy];
                break;
                
            default:
                break;
        }
    }
    
    return YES;
}

/******************************************************
 close the connection
 
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)closeWithError:(NSError **)error {
    BOOL success;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [socketIO closeWithError:error];
                if (success == NO)
                    return NO;
                isConnected = NO;
                break;
                
            default:
                break;
        }
    }
    
    return YES;
}

/******************************************************
 when connecting using a sockets connect a separate connection
 on a different port needs to be made when sending a device clear.
 the instrument provides the port number to use for a device clear.
 run this function after establishing a connection with open function
 
 query: the query to send to the instrument to retrieve the port, pass NULL to use the default
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)queryDeviceClearPort:(NSString *)query error:(NSError **)error {
    BOOL success;
    NSString *response;
    
    @synchronized(self) {
        if (query == NULL)
            query = @"system:communicate:tcpip:control?";
        
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [self query:query response:&response error:error];
                if (success == NO)
                    return NO;
                
                deviceClearPort = [response intValue];
                
                break;
                
            default:
                break;
        }
    
    }
    
    return YES;    
}

/******************************************************
 Send a buffer (an array) to the instrument
 
 buffer: an array to send
 size: the size of the array (bytes)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)printBuffer:(char*)buffer size:(int)size error:(NSError**)error{
    BOOL success;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [socketIO writeBuffer:buffer size:size timeout:printTimeout error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
    }
    
    return YES;
}

/******************************************************
 Send a string (array terminated by \0) to the instrument
 
 message: text string to send
 appendNewLine: should a new line be appended if not present in the message parameter
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)print:(NSString*)message appendNewLine:(BOOL)appendNewLine error:(NSError**)error {
    
    BOOL success;
    NSString* message0;
    
    @synchronized(self) {
        if (appendNewLine) {
            NSRange range = [message rangeOfString:newLineToken];
            if (range.location == NSNotFound || range.location != [message length] - [newLineToken length]) {
                message0 = [message stringByAppendingString:newLineToken];
            }
        }
        else
            message0 = message;
        
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [socketIO writeString:message0 timeout:printTimeout error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
    }
    return YES;   
    
    
}

/******************************************************
 Send a string (array terminated by \0) to the instrument and a new line will be appended to message if not present
 
 message: text string to send
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)print:(NSString*)message error:(NSError**)error {
    BOOL success;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [self print:message appendNewLine:YES error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
    }
    
    return YES;    
}

/******************************************************
 Receive a buffer from the instrument 
 
 buffer: a pointer to an allocated array 
 sizeToRead: size to read from socket (bytes)
 sizeRead: size of that was actually read from the socket (bytes)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)scanBuffer:(char*)buffer sizeToRead:(int)sizeToRead sizeRead:(int*)sizeRead error:(NSError**)error {
    BOOL success;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [socketIO readBuffer:buffer sizeToRead:sizeToRead sizeRead:sizeRead timeout:scanTimeout error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
    }
    
    return YES;    

}

/******************************************************
 Receive a string terminated by a newline (line) from the instrument
 
 response: pointer to a pointer where the string response will be placed.
 the pointer to a pointer should be an unallocated location, or there
 may be a memory leak.
 trimNewLine: should the end line be removed from response after it's read
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)scan:(NSString**)response trimNewLine:(BOOL)trimNewLine error:(NSError**)error {
    
    BOOL success;
    NSString *response0;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [socketIO readLine:response newLineToken:newLineToken timeout:scanTimeout error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
        
        if (trimNewLine) {
            NSRange range = [*response rangeOfString:newLineToken];
            if (range.location != NSNotFound && range.location == [*response length] - [newLineToken length]) {
                response0 = [*response substringToIndex:range.location];
                
                *response = response0;
            }
        }
    }
    
    return YES;   
    
}

/******************************************************
 Receive a string terminated by a newline (line) from the instrument and trim the new line from the response
 
 response: pointer to a pointer where the string response will be placed.
 the pointer to a pointer should be an unallocated location, or there
 may be a memory leak.
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)scan:(NSString**)response error:(NSError**)error {
    BOOL success;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [self scan:response trimNewLine:YES error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
    }
    
    return YES;    

}

/******************************************************
 Receive a binary definite size block(s) as defined in the 488.2 standard for transfering binary.
 some commands transfer data back in binary format to reduce bandwidth as compared to text transfer.
 scpi commands "format real" and "format:border swap" are often used to tell an instrument to use binary.
 You need to deallocate the arrays create in buffers after the call to this function.
 
 blocksCount: number of definite size blocks to read
 buffers: an array of arrays.  The first dimension should be equal to blocksCount.  The second dimension should be deallocated.
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)scanBinaryDefiniteSizeBlocks:(int)blocksCount buffers:(char**)buffers blocksRead:(int *)blocksRead buffersReadSize:(int *)buffersReadSize error:(NSError**)error {
    char smallBuffer[32];
    BOOL success;
    int sizeRead;
    int lengthOfSizeString;
    int blockSize;
    NSString *newLineString;
    
    /* format is:
     [#][length of size field][size field][data]...[data], ...another block... , \n
     */
    
    @synchronized(self) {
        *blocksRead = 0;
        
        for (int b = 0; b < blocksCount; b++) {
            memset(smallBuffer, 0, ARRAY_SIZE(smallBuffer));
            success = [self scanBuffer:smallBuffer sizeToRead:2 sizeRead:&sizeRead error:error];
            if (success != YES)
                return NO;
            
            if (sizeRead != 2) {
                [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"did not read 2 bytes"];
                return NO;
            }
            
            if (smallBuffer[0] != '#') {
                [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"missing #"];
                return NO;
            }    
            
            smallBuffer[0] = smallBuffer[1];
            smallBuffer[1] = '\0';
            lengthOfSizeString = atoi(smallBuffer);
                    
            if (lengthOfSizeString < 0 || lengthOfSizeString > 9) {
                [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"wrong length of size"];
                return NO;
            }
            
            memset(smallBuffer, 0, ARRAY_SIZE(smallBuffer));
            success = [self scanBuffer:smallBuffer sizeToRead:lengthOfSizeString sizeRead:&sizeRead error:error];
            if (success != YES)
                return NO;
            
            if (sizeRead != lengthOfSizeString) {
                [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"did not read length of size bytes"];
                return NO;
            }
            
            blockSize = atoi(smallBuffer);
            
            if (blockSize > 0) {
                buffers[b] = malloc(sizeof(char) * blockSize);
                
                success = [self scanBuffer:buffers[b] sizeToRead:blockSize sizeRead:&sizeRead error:error];
                if (success != YES)
                    return NO;
                
                if (sizeRead != blockSize) {
                    [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"did not read blockSize bytes"];
                    return NO;            
                }
            }
            
            buffersReadSize[b] = blockSize;
            
            if (b != blocksCount - 1) {
                /* read the comma separating blocks */
                memset(smallBuffer, 0, ARRAY_SIZE(smallBuffer));
                success = [self scanBuffer:smallBuffer sizeToRead:1 sizeRead:&sizeRead error:error];
                if (success != YES)
                    return NO;
                
                if (sizeRead != 1) {
                    [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"did not read 1 bytes"];
                    return NO;
                }
                
                if (smallBuffer[0] != ',') {
                    [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"missing ,"];
                    return NO;
                }

            }
            else {
                /* read endline */
                memset(smallBuffer, 0, ARRAY_SIZE(smallBuffer));
                success = [self scanBuffer:smallBuffer sizeToRead:[newLineToken length] sizeRead:&sizeRead error:error];
                if (success != YES)
                    return NO;
                
                if (sizeRead != [newLineToken length]) {
                    [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"did not read newLineToken length bytes"];
                    return NO;
                }
                
                newLineString = [NSString stringWithCString:smallBuffer encoding:NSUTF8StringEncoding];
                
                if (![newLineToken isEqualToString:newLineString]) {
                    [Error setError:error domain:IO_ERROR_DOMAIN code:IO_ERROR_CODE_BADFORMAT description:@"missing new line"];
                    return NO;
                }

                
            }
            
            (*blocksRead)++;
            
        }
    }
    
    return YES;

}

/******************************************************
 Send a string to the instrument, append a newline to the string if one is not present.  
 Receive a string terminated by a newline (line) from the instrument, trim endline from response.
 
 query: the string to send to the instrument
 response: pointer to a pointer where the string response will be placed.
 the pointer to a pointer should be an unallocated location, or there
 may be a memory leak.
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)query:(NSString*)query response:(NSString**)response error:(NSError**)error {
    BOOL success;
    
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                success = [self print:query error:error];
                if (success == NO)
                    return NO;
                
                success = [self scan:response error:error];
                if (success == NO)
                    return NO;
                break;
                
            default:
                break;
        }
    }
    
    return YES;    
    
    
}

/******************************************************
 Send device clear to the instrument.  A device clear is needed when the instrument
 command parser is in a bad state and is not responding.
 
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)deviceClearWithError:(NSError **)error {
    BOOL success;
    SocketIO *dclrSocketsIO;
    
    @synchronized(self) {
        switch (ioType) {
            case IO_TYPE_SOCKETS:
                dclrSocketsIO = [[SocketIO alloc] init];
                
                success = [dclrSocketsIO openWithAddress:addressConnected port:deviceClearPort timeout:connectTimeout error:error];
                if (success == NO)
                    return NO;
                
                success = [self print:@"DCL" error:error];
                if (success == NO)
                    return NO;
                
                [dclrSocketsIO closeWithError:error];
                if (success == NO)
                    return NO;
                
                [dclrSocketsIO release];
                
                break;
                
            default:
                break;
        }
    }
    
    return YES;

    
    
}



@end

