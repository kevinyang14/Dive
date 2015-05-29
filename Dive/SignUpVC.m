//
//  SignUpVC.m
//  Dive
//
//  Created by Kevin Yang on 3/9/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "SignUpVC.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "Backendless.h"
#import <Parse/Parse.h>

@interface SignUpVC () <UITextFieldDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicImageView;
@end

@implementation SignUpVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupKeyboards];
    self.profilePicImageView.layer.cornerRadius = 35;
    self.profilePicImageView.layer.masksToBounds = YES;
    [self.firstNameField becomeFirstResponder];
}

#pragma mark TextFields

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark CameraMethods

+ (BOOL)canAddPhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return YES;
    }
    return NO;
}

#pragma mark ImagePickerDelegateMethods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    self.profilePicImageView.image = image;
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark AddProfilePic

- (IBAction)addProfPic:(UIButton *)sender {
    if (![[self class] canAddPhoto]) {
        [self alertWithTitle:@"Warning" andMessage:@"This device has no camera fool!"];
    }else{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.mediaTypes = @[(NSString *)kUTTypeImage];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = YES;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

#pragma mark Sign Up

- (IBAction)back:(id)sender {
    [self dismissKeyboard];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)signUp:(UIButton *)sender {
    [self dismissKeyboard];
    [self parseUserRegistration];
//    [self backendlessUserRegistration];
}


#pragma mark Parse


- (void)parseUserRegistration
{
    NSString *firstName = self.firstNameField.text;
    NSString *lastName = self.lastNameField.text;
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;
    if(firstName.length == 0 || lastName.length == 0 || email.length == 0 || password.length == 0){
        [self alertWithTitle:@"Oops" andMessage:@"You forgot to fill up something"];
    }else{
        PFUser *user = [PFUser user];
        user.username = email;
        user.email = email;
        user.password = password;
        [user setObject:firstName forKey:@"firstName"];
        [user setObject:lastName forKey:@"lastName"];
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                //Success!
                [self performSegueWithIdentifier:@"SignUp" sender:nil];
            }else{
                [self alertWithTitle:[[error userInfo] objectForKey:@"error"] andMessage:nil];
                [self.firstNameField becomeFirstResponder]; //bring back keyboard
                return;
            }
        }];
    }
}


#pragma mark Backendless


-(void)backendlessUserRegistration
{
    BackendlessUser *user = [BackendlessUser new];
    user.name = [NSString stringWithFormat:@"%@ %@",self.firstNameField.text, self.lastNameField.text];
    user.email = self.emailField.text;
    user.password = self.passwordField.text;

    Responder *responder = [Responder responder:self
                             selResponseHandler:@selector(responseHandler:)
                                selErrorHandler:@selector(errorHandler:)];
    [backendless.userService registering:user responder:responder];
}

-(id)responseHandler:(id)response
{
    BackendlessUser *user = (BackendlessUser *)response;
    NSLog(@"signed up!");
    [self performSegueWithIdentifier:@"SignUp" sender:nil];
    return user;
}
          
          
-(void)errorHandler:(Fault *)fault
{
    [self alertWithTitle:@"Oops" andMessage:fault.message];
}


#pragma mark HelperMethods

- (void)setupKeyboards
{
    [self dismissKeyboard];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    [self.emailField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.firstNameField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.lastNameField setAutocorrectionType:UITextAutocorrectionTypeNo];
}

- (void)dismissKeyboard
{
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (BOOL)prefersStatusBarHidden {return YES;}

-(void)alertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
    
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
