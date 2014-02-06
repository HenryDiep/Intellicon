//
//  Socket.m
//  A class to perform socket I/O communication with higher level features like timeout.
//  BSD sockets are used.
//  You can open a connection, write, read data, and close.
//
//  Created by Tom Furman on 5/3/11.
//  Copyright 2011 Agilent Technologies, Inc. All rights reserved.
//

#import "SocketIO.h"
#include "Error.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <netinet/tcp.h>
#include <time.h>
#include <fcntl.h>

@implementation SocketIO


/*******************************************************
 Initalize class 
 
 returns: self reference
*******************************************************/
- (id)init {
    sockd = 0;
    [super init];
    
    return self;
}

/******************************************************
 Attempt to open a socket to the specific address
 
 address: ip or hostname
 port: port number
 timeout: time to wait until give up on connection attempt (ms)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
*******************************************************/
- (BOOL)openWithAddress:(NSString*)address port:(int)port timeout:(int)timeout error:(NSError**)error {
	struct sockaddr_in serv_name;
    int status;
	const char *addr = [address UTF8String];
	int flags;
    BOOL success;
    BOOL ret;

	/* create a socket */
    sockd = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
	if (sockd == -1) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Unable to create socket" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_UNABLE_TO_CREATE_SOCKET userInfo:errorDetail];
		return NO;
	}
    // turn of nagle algorithm... optimization that slows down the case of write, write, read to instrument
    flags = 1;
	setsockopt(sockd, IPPROTO_TCP, TCP_NODELAY, (char*)&flags, sizeof flags);
    
    flags = fcntl(sockd, F_GETFL, 0); //get default flags
	fcntl(sockd, F_SETFL, flags | O_NONBLOCK); //set sock to nonblock so we can use connect timeout

	/* server address */ 
    //memset(&serv_name, 0, sizeof(serv_name)); 
	serv_name.sin_family = AF_INET;
	inet_aton(addr, &serv_name.sin_addr);
	serv_name.sin_port = htons(port);
	
	/* connect to the server */
	status = connect(sockd, (struct sockaddr*)&serv_name, sizeof(serv_name));
	
    if (status == 0) /* successfully connected */
        ret = YES;
    else if (status == -1 && errno != EINPROGRESS) { /* unsuccessful connection */
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Unable to connect" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_UNABLE_TO_CONNECT userInfo:errorDetail];
		ret = NO;		
        
	}
    else if (status == -1 && errno == EINPROGRESS) { /* connection in progress, use timeout */
        success = [self waitForConnectSignal:timeout error:error];
        if (success == NO)
            ret = NO;
        else
            ret = YES;
    }
    else
        ret = NO;
    
    fcntl(sockd, F_SETFL, flags); /* restore default flags */

    
    return ret;	
}


/******************************************************
 Close the socket session
 
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)closeWithError:(NSError**)error {
	close(sockd);
    
    return YES;
}

/******************************************************
 Send a string (array terminated by \0) to the socket
 
 string: text string to send
 timeout: time to wait until give up on send attempt (ms)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)writeString:(NSString*)string timeout:(int)timeout error:(NSError**)error {
	char *buffer = (char*)[string UTF8String];	
    int size = strlen(buffer);
    
	return [self writeBuffer:buffer size:size timeout:timeout error:error];	
}

/******************************************************
 Send a buffer (an array) to the socket
 
 buffer: an array to send
 size: the size of the array (bytes)
 timeout: time to wait until give up on send attempt (ms)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)writeBuffer:(char*)buffer size:(int)size timeout:(int)timeout error:(NSError**)error  {
    char* buffer0;
    int bytesRemaining, bytesWritten;
    unsigned long startTick, ticksPassed;
    int timeout0 = timeout;
    BOOL success;
    
    buffer0 = buffer;
    bytesRemaining = size;
    
    /* send until the entire buffer has been sent or timeout reached */
    while (bytesRemaining > 0) {
        startTick = [self getCurrentTime];
        success = [self waitForSendSignal:timeout0 error:error];
        if (success == NO)
            return NO;
        
        bytesWritten = send(sockd, buffer0, bytesRemaining, 0);
        
        if (bytesWritten == -1) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Error sending" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_WRITING userInfo:errorDetail];
            return NO;	            
        }
        
        /* move the buffer pointer by the amount sent */
        bytesRemaining -= bytesWritten;
        buffer0 += bytesWritten;
        
        /* adjust timeout variables */
        ticksPassed = [self getCurrentTime] - startTick;    
        timeout0 -= ticksPassed;

    }
    
    return YES;
}


/******************************************************
 Receive a buffer from the socket 
 
 buffer: a pointer to an allocated array 
 sizeToRead: size to read from socket (bytes)
 sizeRead: size of that was actually read from the socket (bytes)
 timeout: time to wait until give up on receive attempt (ms)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)readBuffer:(char*)buffer sizeToRead:(int)sizeToRead sizeRead:(int*)sizeRead timeout:(int)timeout error:(NSError**)error {
    char* buffer0;
    int bytesRemaining, bytesRead;
    unsigned long startTick, ticksPassed;
    int timeout0 = timeout;
    BOOL success;
    
    bytesRemaining = sizeToRead;    
    buffer0 = buffer;

    /* read until the number of expected bytes was read or timeout reached */
    while (bytesRemaining > 0) {
        startTick = [self getCurrentTime];
        success = [self waitForRecvSignal:timeout0 error:error];
        if (success == NO)
            return NO;
        
        bytesRead = recv(sockd, buffer0, bytesRemaining, 0);
        if (bytesRead < 0) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Error reading" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING userInfo:errorDetail];
            return NO;	            
            
        }
        
        /* move the buffer pointer by the amount received */
        bytesRemaining -= bytesRead;
        buffer0 += bytesRead;
        
        /* adjust timeout variables */
        ticksPassed = [self getCurrentTime] - startTick;    
        timeout0 -= ticksPassed;
        
    }

    *sizeRead = sizeToRead - bytesRemaining;
    
    return YES;
}

/******************************************************
 Receive a string terminated by a newline (line) from the socket
 
 response: pointer to a pointer where the string response will be placed.
           the pointer to a pointer should be an unallocated location, or there
           may be a memory leak.
 newLineToken: character(s) specifing a new line (\n)
 timeout: time to wait until give up on receive attempt (ms)
 error: object where error information will be placed
 
 returns: YES on success.  NO on error.
 *******************************************************/
- (BOOL)readLine:(NSString**)response newLineToken:(NSString *)newLineToken timeout:(int)timeout error:(NSError**)error {
    int bufferSize = 128;
    char buffer[bufferSize];
    int bytesRead;
    unsigned long startTick, ticksPassed;
    unsigned long timeout0 = timeout;
    NSString* localString = [[NSString alloc ] init];
    BOOL success;
    const char *newLineToken0 = [newLineToken UTF8String];

    /* read until a newline was read or timeout reached */
    while (true) {
        startTick = [self getCurrentTime];
        success = [self waitForRecvSignal:timeout0 error:error];
        if (success == NO)
            return NO;
        
        bytesRead = recv(sockd, buffer, bufferSize - 1, 0);
        if (bytesRead < 0) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Error reading" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING userInfo:errorDetail];
            return NO;	            
            
        }
        /* add a null at the end of array to signify end of string */
        buffer[bytesRead] = '\0';
        /* convert received array to NSString and append string - note this gets AutoReleased*/
        localString = [localString stringByAppendingString:[NSString stringWithUTF8String:(char*)buffer]];        
        
        /* look for end of line token in the received string */
        if (strstr(buffer, newLineToken0) - buffer == bytesRead - strlen(newLineToken0))
            break;
        
        /* adjust timeout variables */
        ticksPassed = [self getCurrentTime] - startTick;        
        timeout0 -= ticksPassed;
        
    }
    
    *response = localString;
    
    return YES;
}

/******************************************************
 private function for performaing a receive timeout.
 the function will block until data is available for reading from the socket
 and then return YES.  Otherwise it will stop blocking after timeout and return NO.
 
 timeout: time to wait
 error: object where error information will be placed
 
 returns: YES on success.  NO on error or timeout.
 *******************************************************/
- (BOOL)waitForRecvSignal:(int)timeout error:(NSError**)error {
    fd_set readfds;
	struct timeval timevalObj;
	int ret;

    FD_ZERO(&readfds);
    FD_SET(sockd, &readfds);
   
	/* Initialize the timeout structure. */
	timevalObj.tv_sec = timeout / 1000;
	timevalObj.tv_usec = (timeout % 1000) * 1000;

    /* Wait for socket data to be received. */
	ret = select(sockd + 1, &readfds, NULL, NULL, &timevalObj);
    
	if (ret == -1) {
        [Error setError:error domain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING description:@"socket error"];
        return NO;	            
	}	
	
    if (ret == 0) {
        [Error setError:error domain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING description:@"timeout"];
        return NO;		
    }
    
    
    return YES;
}

/******************************************************
 private function for performaing a send timeout
 the function will block until socket is ready for sending
 and then return YES.  Otherwise it will stop blocking after timeout and return NO.
 
 timeout: time to wait
 error: object where error information will be placed
 
 returns: YES on success.  NO on error or timeout.
*******************************************************/
- (BOOL)waitForSendSignal:(int)timeout error:(NSError**)error {
    fd_set writefds;
	struct timeval timevalObj;
	int ret;
  
    FD_ZERO(&writefds);
    FD_SET(sockd, &writefds);
    
	/* Initialize the timeout structure. */
	timevalObj.tv_sec = timeout / 1000;
	timevalObj.tv_usec = (timeout % 1000) * 1000;
    
    /* Wait for socket data to be received. */
	ret = select(sockd + 1, NULL, &writefds, NULL, &timevalObj);
    
	if (ret == -1) {
        [Error setError:error domain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING description:@"socket error"];
        return NO;	            
	}	
	
    if (ret == 0) {
        [Error setError:error domain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING description:@"timeout"];
        return NO;		
    }
    
    return YES;
}

/******************************************************
 private function for performaing a connect timeout
 the function will block until socket connected successfully
 and then return YES.  Otherwise it will stop blocking after timeout and return NO.
 
 timeout: time to wait
 error: object where error information will be placed
 
 returns: YES on success.  NO on error or timeout.
 *******************************************************/
- (BOOL)waitForConnectSignal:(int)timeout error:(NSError**)error {
    fd_set readfds, writefds;
	struct timeval timevalObj;
	int ret;
    
    FD_ZERO(&writefds);
    FD_SET(sockd, &writefds);
    
    FD_ZERO(&readfds);
    FD_SET(sockd, &readfds);
    
	/* Initialize the timeout structure. */
	timevalObj.tv_sec = timeout / 1000;
	timevalObj.tv_usec = (timeout % 1000) * 1000;  /* note: can't put entire timeout value as us */
    
    /* Wait for socket data to be received. */
	ret = select(sockd + 1, &readfds, &writefds, NULL, &timevalObj);
    
	if (ret == -1) {
        [Error setError:error domain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING description:@"unable to connect"];
        return NO;	            
	}	
	
    if (ret == 0) {
        [Error setError:error domain:SOCKETIO_ERROR_DOMAIN code:SOCKETIO_ERROR_CODE_ERROR_READING description:@"timeout"];
        return NO;		
    }
    
    return YES;
}

/******************************************************
 private function for getting the current time in milliseconds 
 for performing time deltas
  
 returns: the computer time (ms)
 *******************************************************/
- (long)getCurrentTime {
    clock_t c = clock();
    long ms = c * 1000.0 / CLOCKS_PER_SEC;
    return ms;
}

@end
