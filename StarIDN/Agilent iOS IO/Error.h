//
//  Error.h
//  N6705BControl
//
//  Created by Tom Furman on 5/6/11.
//  Copyright 2011 Agilent Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Error : NSObject {
    
}

+ (void)setError:(NSError **)error domain:(NSString *)domain code:(NSInteger)code description:(NSString *)description;

@end
