//
//  Error.m
//  N6705BControl
//
//  Created by Tom Furman on 5/6/11.
//  Copyright 2011 Agilent Technologies, Inc. All rights reserved.
//

#import "Error.h"


@implementation Error


/******************************************************
 Helper function to create an NSError object with the specific parameters
 *******************************************************/
+ (void)setError:(NSError **)error domain:(NSString *)domain code:(NSInteger)code description:(NSString *)description {
    if (error != NULL) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:description forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:domain code:code userInfo:errorDetail];
    }
}

@end