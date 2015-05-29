//
//  VideoCameraVC.m
//  Dive
//
//  Created by Kevin Yang on 3/9/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "VideoCameraVC.h"
#import "Backendless.h"
#import "MediaService.h"

#define VIDEO_TUBE @"videoTube"
#define DEFAULT_STREAM_NAME @"diveIn"

@interface VideoCameraVC () <IMediaStreamerDelegate>

@property (nonatomic, strong) MediaPublisher *publisher;
@property (nonatomic, strong) MediaPlayer *player;
@property (nonatomic, assign) BOOL canShow;
@property (nonatomic, strong) UIActivityIndicatorView *netActivity;
@property (weak, nonatomic) IBOutlet UIImageView *preview;
@property (weak, nonatomic) IBOutlet UIImageView *playbackView;
@end

@implementation VideoCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
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
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error:" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
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


#pragma mark -
#pragma mark IBAction

- (IBAction)publish:(UIButton *)sender {
    NSLog(@"publishControl: -> backendless.mediaService: %@ [%@]", backendless.mediaService, [Types classByName:@"MediaService"]);
    
    MediaPublishOptions *options = [MediaPublishOptions liveStream:self.preview];
    options.orientation = AVCaptureVideoOrientationPortrait;
    options.resolution = RESOLUTION_CIF;
    self.publisher =[backendless.mediaService publishStream:DEFAULT_STREAM_NAME tube:VIDEO_TUBE options:options responder:self];
    
    //UPLOAD GEOPOINT HERE
    
    [self.netActivity startAnimating];
}

- (IBAction)stop:(UIButton *)sender {
    if (self.publisher)
    {
        [self.publisher disconnect];
        self.publisher = nil;
//        self.preview.hidden = YES;
    }
    
    if (self.player)
    {
        [self.player disconnect];
        self.player = nil;
//        self.playbackView.hidden = YES;
    }

    
    [self.netActivity stopAnimating];
}

- (IBAction)flipCamera:(UIButton *)sender {
    if (self.publisher)
        [self.publisher switchCameras];
}

#pragma mark -
#pragma mark IMediaStreamerDelegate Methods

-(void)streamStateChanged:(id)sender state:(int)state description:(NSString *)description {
    
    NSLog(@"<IMediaStreamerDelegate> streamStateChanged: %d = %@", (int)state, description);
    
    switch (state) {
            
        case CONN_DISCONNECTED: {
            
            if ([description isEqualToString:@"streamIsBusy"]) {
                [self showAlert:[NSString stringWithString:description]];
            }
            
            [self stop:sender];
            break;
        }
            
        case CONN_CONNECTED: {
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
            
            [self stop:sender];
            break;
        }
            
        case STREAM_PLAYING: {
            
            // PUBLISHER
            if (self.publisher) {
                
                if (![description isEqualToString:@"NetStream.Publish.Start"]) {
                    [self stop:sender];
                    break;
                }
                
                self.preview.hidden = NO;
                [self.netActivity stopAnimating];
            }
            
            // PLAYER
            if (self.player) {
                
                if ([description isEqualToString:@"NetStream.Play.StreamNotFound"]) {
//                    [self showAlert:[NSString stringWithString:description]];
                    [self showAlert:@"CONNECTION ERROR"];
                    [self stop:sender];
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
    
    [self stop:sender];
    
    [self showAlert:(code == -1) ?
     [NSString stringWithFormat:@"Unable to connect to the server. Make sure the hostname/IP address and port number are valid\n"] :
     [NSString stringWithFormat:@"connectFailedEvent: %@ \n", description]];
}

- (IBAction)watch:(UIButton *)sender {
    [self playLiveStream:DEFAULT_STREAM_NAME tube:VIDEO_TUBE];
}

-(void)playLiveStream:(NSString *)streamName
                 tube:(NSString *)tubeName
{
    MediaPlaybackOptions *options = [MediaPlaybackOptions liveStream:self.playbackView];
    options.orientation = UIImageOrientationUp;
    options.isLive = YES;

    
    self.player =[backendless.mediaService
                  playbackStream:streamName
                  tube:tubeName
                  options:options
                  responder:self];
    
    [self.netActivity startAnimating];
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
