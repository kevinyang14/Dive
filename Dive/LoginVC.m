//
//  LoginVC.m
//  Dive
//
//  Created by Kevin Yang on 3/9/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "LoginVC.h"
#import "Backendless.h"
#import <Parse/Parse.h>

@interface LoginVC ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@end

@implementation LoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.emailField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.emailField becomeFirstResponder];
}

#pragma mark HelperMethods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)alertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (BOOL)prefersStatusBarHidden {return YES;}

#pragma mark Login

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


- (IBAction)login:(UIButton *)sender {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    
    [self parseLogin];
//    [self backendlessLogin];
}

#pragma mark Parse Login

- (void)parseLogin
{
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;
    
    if(email.length == 0 || password.length == 0 || [password  isEqual: @"Password"] || [email  isEqual: @"Email"]){
        //warn user to fill in all fields
        [self alertWithTitle:@"Oops" andMessage:@"You forgot to fill up something"];
        return;
    }
    
    [PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
        if (user) {
            [self performSegueWithIdentifier:@"LogIn" sender:nil];
//            [self associateDeviceWithUser];
        }else{
            [self alertWithTitle:[[error userInfo] objectForKey:@"error"] andMessage:nil];
            [self.emailField becomeFirstResponder];
        }
    }];
}

#pragma mark Backendless Login

-(void)backendlessLogin
{
    Responder *responder = [Responder responder:self
                             selResponseHandler:@selector(responseHandler:)
                                selErrorHandler:@selector(errorHandler:)];
    [backendless.userService login:self.emailField.text password:self.passwordField.text responder:responder];
}
     
-(id)responseHandler:(id)response;
{
    BackendlessUser *user = (BackendlessUser *)response;
    NSLog(@"logged in!");
    [self performSegueWithIdentifier:@"LogIn" sender:nil];
    return user;
}
      
-(void)errorHandler:(Fault *)fault
{
    [self alertWithTitle:@"Oops" andMessage:fault.message];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
