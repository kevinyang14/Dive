//
//  WatchStreamVC.m
//  Dive
//
//  Created by Kevin Yang on 3/11/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "WatchStreamVC.h"
#import "Backendless.h"
#import "MediaService.h"

@interface WatchStreamVC () <IMediaStreamerDelegate>
@property (nonatomic, strong) MediaPlayer *player;
@property (nonatomic, assign) BOOL canShow;
@property (nonatomic, strong) UIActivityIndicatorView *netActivity;
@property (weak, nonatomic) IBOutlet UIImageView *videoView;
@property (weak, nonatomic) IBOutlet UIView *messageView;
@end

@implementation WatchStreamVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    if(self.liveStream)[self start];
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

- (IBAction)back:(UIButton *)sender {
    [self stop];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Stream Methods

-(void)start{
    MediaPlaybackOptions *options = [MediaPlaybackOptions liveStream:self.videoView];
    options.orientation = UIImageOrientationUp;
    options.isLive = YES;
    
    NSLog(@"/n/n/nTubename: %@ StreamName: %@/n/n/n", self.liveStream[@"tubeName"], self.liveStream[@"fileName"]);
    self.player =[backendless.mediaService
                  playbackStream:self.liveStream[@"fileName"]
                  tube:self.liveStream[@"tubeName"]
                  options:options
                  responder:self];
    
    [self.netActivity startAnimating];
}

-(void)stop{
    if (self.player)
    {
        [self.player disconnect];
        self.player = nil;
    }
}

#pragma mark -
#pragma mark IMediaStreamerDelegate Methods

-(void)streamStateChanged:(id)sender state:(int)state description:(NSString *)description {
    switch (state) {
        case CONN_DISCONNECTED: {
            if ([description isEqualToString:@"streamIsBusy"]) {
                [self showAlert:[NSString stringWithString:description]];
            }
            [self stop];
            break;
        }

        case CONN_CONNECTED: {
            [self.netActivity stopAnimating];
            break;
        }
            
        case STREAM_CREATED: {
            break;
        }
            
        case STREAM_PAUSED: {
            if ([description isEqualToString:@"NetStream.Play.StreamNotFound"]) {
                //                [self showAlert:[NSString stringWithString:description]];
                [self showAlert:@"PAUSED"];
            }
            [self stop];
            break;
        }
            
        case STREAM_PLAYING: {
            // PLAYER
            if (self.player) {
                
                if ([description isEqualToString:@"NetStream.Play.StreamNotFound"]) {
                    //                    [self showAlert:[NSString stringWithString:description]];
                    self.messageView.hidden = NO;
                    [self showAlert:@"CONNECTION ERROR"];
                    [self stop];
                    break;
                }
                
                if ([description isEqualToString:@"NetStream.Play.Start"]) {
                    //                    [self showAlert:[NSString stringWithString:description]];
                    [self.netActivity stopAnimating];
                    break;
                }
                
                //                self.playbackview.hidden = NO;
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
