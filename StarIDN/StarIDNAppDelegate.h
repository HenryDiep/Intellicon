//
//  StarIDNAppDelegate.h
//  StarIDN
//
//  Created by Neil Hayden on 8/9/11.
//  Copyright 2011 Agilent Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StarIDNViewController;

@interface StarIDNAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet StarIDNViewController *viewController;

@end
