//
//  StarIDNViewController.m
//  StarIDN
//
//  Created by Neil Forcier on 8/9/11.
//  Copyright 2011 Agilent Technologies. All rights reserved.
//

#import "StarIDNViewController.h"

@implementation StarIDNViewController
@synthesize message, ipTextField;

#pragma mark - button methods

-(IBAction)goConnect { //connect button action method
	
	if (connected) { //make sure not already connected
		self.message.text = @"Already Connected";
	}
	else {
        
        if (![io openWithAddress:self.ipTextField.text port:5025 error:&hError]) { //connect to the instrument with entered IP address and 5025 port 
			connected = FALSE;
			self.message.text = [[NSString alloc] initWithString:[hError localizedDescription]]; //display error if connection failed
            
		}
		else { //the connection was a success
			self.message.text = @"Connected"; 
			connected = TRUE;
		}
	}
    
}

-(IBAction)goSendRec { //send / recieve action method
    NSString *response; //create string pointer to get response from instrument
	
	if (connected) {
        if(![io query:@"*idn?" response:&response error:&hError]) { //Send *IDN? SCPI command and read the result in "response" string
            self.message.text = [[NSString alloc] initWithString:[hError localizedDescription]];} //if this is reached send / recv failed check hError
        else {
            self.message.text = response; //if you get here send / rec worked so get IDN string
        }
		//self.message.text = [myNetwork sendRecieve:@"*IDN?\n"];
	}
	else {
		self.message.text = @"Must Connect First"; //display this if not connected to instrument
	}
    
}

-(IBAction)goDisconnect { //disconnect button action method
	
    [io closeWithError:&hError]; //close connection. I don't bother checking for error since example
	self.message.text = @"Not Connected";
	connected = FALSE;
}

#pragma mark - keyboard methods
//**************** beginning of textfield and keyboard functions **********

//override viewWillAppear; keyboard will show notification
-(void)viewWillAppear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window];
	
	[super viewWillAppear:animated];
}

//override viewWillDisappear
- (void)viewWillDisappear:(BOOL)animated {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	
	[super viewWillDisappear:animated];
}

//determine keyboard size and decide whether to scroll view up or not
- (void)keyboardWillShow:(NSNotification *)notif {
	
	NSDictionary* info = [notif userInfo];
	//NSValue *aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
    NSValue *aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;
	float bottomPoint = (ipTextField.frame.origin.y + ipTextField.frame.size.height + 10);
	scrollAmount = keyboardSize.height - (self.view.frame.size.height - bottomPoint);
	
	if (scrollAmount > 0) {
		moveViewUp = YES;
		[self scrollTheView:YES];	
	}
	else {
		moveViewUp = NO;
	}
}

//scrolls the view for the keyboard if needed
-(void)scrollTheView:(BOOL)movedUp {
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	CGRect rect = self.view.frame;
	if (movedUp) {
		rect.origin.y -= scrollAmount;
	}
	else {
		rect.origin.y += scrollAmount;	
	}
	self.view.frame = rect;
	[UIView commitAnimations];
}

//dismiss the keyboard
-(BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	
	[theTextField resignFirstResponder];
	if (moveViewUp) {
		[self scrollTheView:NO];
	}
	
	return YES;
}

//override touchesBegan:: this function will dismiss keyBoard if touch in view
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (ipTextField.editing) {
		[ipTextField resignFirstResponder];
		//this is where you would save IP address
		if (moveViewUp) {
			[self scrollTheView:NO];
		}
	}
	
	[super touchesBegan:touches withEvent:event];
}
//*********** end of textfield and keyboard functions ****************

- (void)dealloc //get rid of all dynamic variables
{
    [message release];
    [ipTextField release];
    [io release];
    [hError release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    io = [[AiOS_IO alloc] init]; //alloc and init for io which is a AiOS_IO object
    hError = nil; //set error object to nil until error is encountered
	connected = FALSE; //app just started up so we are not connected
	self.ipTextField.text = @"04.27.79.666";
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
