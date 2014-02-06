//
//  StarIDNViewController.h
//  StarIDN
//
//  Created by Neil Hayden on 8/9/11.
//  Copyright 2011 Agilent Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AiOS_IO.h"

@interface StarIDNViewController : UIViewController {
    IBOutlet UILabel *message; //this is the Label object used to display *IDN? response
	IBOutlet UITextField *ipTextField; //textfield object
    AiOS_IO *io; //declare object to access IO class
    NSError *hError; 
    //NSError objects handle an error condition save the info and allow the code to keep flowing, much better than try / catch
	BOOL connected;  //bool for whether TCP/IP connection has been established with instrument
	BOOL moveViewUp; //bool for whether to move move view up for keyboard
	CGFloat scrollAmount; //How much to move view up when keyboard shows
}

@property (nonatomic, retain) UILabel *message;
@property (nonatomic, retain) UITextField *ipTextField;

-(IBAction)goConnect; //connect button action method
-(IBAction)goSendRec; //send / recieve action method
-(IBAction)goDisconnect; //disconnect button action method
-(void)scrollTheView:(BOOL)movedUp; //scrolls view up when keyboard shows


@end
