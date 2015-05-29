//
//  BroadcastVC.m
//  Dive
//
//  Created by Kevin Yang on 3/10/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "BroadcastVC.h"
#import "Backendless.h"
#import "MediaService.h"
#import <Parse/Parse.h>

#define VIDEO_TUBE @"videoTube"
#define DEFAULT_STREAM_NAME @"obamaLIVE"

@interface BroadcastVC ()  <IMediaStreamerDelegate>
@property (nonatomic, strong) MediaPublisher *publisher;
@property (nonatomic, assign) BOOL canShow;
@property (nonatomic, strong) UIActivityIndicatorView *netActivity;
@property (weak, nonatomic) IBOutlet UIImageView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *messageView;
@property (nonatomic, strong) PFObject *liveStream;
@property (nonatomic, strong) NSString *tubeName;
@end

@implementation BroadcastVC

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"\n\n\nBroadcastVC FileName: %@\n\n\n", self.streamFileName);
    [self setupUI];
    [self start];
}

- (void)setupUI{
    self.messageView.hidden = YES;
    self.canShow = YES;
    @try {
        [backendless initAppFault];
        [self initNetActivity];
    }
    @catch (Fault *fault) {
        NSLog(@"initAppFault -> %@", fault);
        [self showAlert:fault.message];
    }
}

#pragma mark Private Methods

-(void)showAlert:(NSString *)message {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Oops" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [av show];
}

-(void)initNetActivity {
    
    // isPad fixes kind of device: iPad (YES) or iPhone (NO)
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    // Create and add the activity indicator
    self.netActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:isPad?UIActivityIndicatorViewStyleGray:UIActivityIndicatorViewStyleWhiteLarge];
    self.netActivity.center = isPad? CGPointMake(400.0f, 480.0f) : CGPointMake(160.0f, 240.0f);
    [self.view addSubview:self.netActivity];
}

#pragma mark Stream Methods

-(void)start{
    MediaPublishOptions *options = [MediaPublishOptions liveStream:self.cameraView];
    options.orientation = AVCaptureVideoOrientationPortrait;
    options.resolution = RESOLUTION_MEDIUM;
    self.tubeName = [self getRandomTubeName];
    self.publisher =[backendless.mediaService publishStream:self.streamFileName tube:self.tubeName options:options responder:self];

    [self.netActivity startAnimating];
}


-(void)stop{
    if (self.publisher)
    {
        [self.publisher disconnect];
        self.publisher = nil;
    }
    [self.netActivity stopAnimating];
}

#pragma mark Parse Methods


- (void)uploadStreamToParse
{
    self.liveStream = [PFObject objectWithClassName:@"LiveStream"];
    [self.liveStream setObject:self.streamName forKey:@"streamName"];
    [self.liveStream setObject:self.streamFileName forKey:@"fileName"];
    [self.liveStream setObject:self.tubeName forKey:@"tubeName"];
    [self.liveStream setObject:@(0) forKey:@"numViewers"];
    [self.liveStream setObject:[PFUser currentUser] forKey:@"user"];
    [self.liveStream setObject:@"TRUE" forKey:@"isLive"];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (!error) {
            [self.liveStream setObject:geoPoint forKey:@"location"];
            [self.liveStream saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    //SUCCESS
                }else{
                    [self alertWithTitle:@"Oops" andMessage:@"Something went wrong. Please try again :)"];
                }
            }];
        }
    }];
}

- (void)closeLiveStreamOnParse
{
    [self.liveStream setObject:@"FALSE" forKey:@"isLive"];
    [self.liveStream saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            //SUCCESS
        }else{
            [self alertWithTitle:@"Oops" andMessage:@"Something went wrong. Please try again :)"];
        }
    }];

}


#pragma mark IBAction

- (IBAction)endStream:(UIButton *)sender {
    if([sender.currentTitle isEqualToString:@"END"]){
        [self stop];
        self.messageView.hidden = NO;
        [sender setBackgroundColor:[self getLightBlue]];
        [sender setTitle:@"BACK" forState:UIControlStateNormal];
        [self closeLiveStreamOnParse];
    }else{
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (IBAction)flip:(id)sender {
    if (self.publisher)
        [self.publisher switchCameras];
}


#pragma mark IMediaStreamerDelegate Methods

-(void)streamStateChanged:(id)sender state:(int)state description:(NSString *)description {
    NSLog(@"<IMediaStreamerDelegate> streamStateChanged: %d = %@", (int)state, description);
    switch (state) {
        case CONN_DISCONNECTED: {
            if ([description isEqualToString:@"streamIsBusy"]) {
                [self showAlert:[NSString stringWithString:description]];
            }
            [self stop];
            break;
        }
            
        case CONN_CONNECTED: {
            break;
        }
            
        case STREAM_CREATED: {
            [self uploadStreamToParse];
            break;
        }
            
        case STREAM_PAUSED: {
            if ([description isEqualToString:@"NetStream.Play.StreamNotFound"]) {
                [self showAlert:@"PAUSED"];
            }
            [self stop];
            break;
        }
            
        case STREAM_PLAYING: {
            // PUBLISHER
            if (self.publisher) {
                if (![description isEqualToString:@"NetStream.Publish.Start"]) {
                    [self stop];
                    break;
                }
                [self.netActivity stopAnimating];
            }
            break;
        }
        default:
            break;
    }
}

-(void)streamConnectFailed:(id)sender code:(int)code description:(NSString *)description {
    NSLog(@"<IMediaStreamerDelegate> streamConnectFailed: %d = %@", code, description);
    [self stop];
    [self showAlert:(code == -1) ?
     [NSString stringWithFormat:@"Unable to connect to the server. Make sure the hostname/IP address and port number are valid\n"] :
     [NSString stringWithFormat:@"connectFailedEvent: %@ \n", description]];
}


#pragma mark Helper Methods

- (NSString*)getRandomTubeName
{
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *tubeName = [NSMutableString stringWithCapacity:10];
    for (NSUInteger i = 0U; i < 10; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [tubeName appendFormat:@"%C", c];
    }
    return tubeName;
}

- (UIStatusBarStyle)preferredStatusBarStyle{return UIStatusBarStyleLightContent;}

-(void)alertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (UIColor *)getLightBlue{ return [[UIColor alloc] initWithRed:21.0/255.0 green:153.0/255.0 blue:169.0/255.0 alpha:0.5];}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
