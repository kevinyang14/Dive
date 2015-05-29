//
//  DiveFeedTVC.m
//  Dive
//
//  Created by Kevin Yang on 3/9/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import "DiveFeedTVC.h"
#import "BroadcastVC.h"
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Parse/Parse.h>
#import "LiveStreamCell.h"
#import "WatchStreamVC.h"
#import "AppDelegate.h"

#define MAX_SEARCH_DISTANCE 50.0

@interface DiveFeedTVC ()<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableString *streamName;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSMutableArray *liveStreamsArray;
@property (strong, nonatomic) PFObject *watchLiveStream;
@end

@implementation DiveFeedTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupLocation];
    [self setupRefreshControl];
    [self fetchAllStreams];
}

- (void)setupUI
{
    //make status bar white
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    //change topbar color or pattern
    self.navigationController.navigationBar.barTintColor = [self getLightBlue];  //set topbar collor
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    //clear tableviewcell separator
    self.tableView.separatorColor = [UIColor clearColor];
    
    //clear tableview background
    self.tableView.backgroundColor = [self getSpaceGrey];
}

- (void)setupLocation
{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];

}

- (void)setupRefreshControl
{
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:self.refreshControl];
    [self.refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
}


- (void)refreshTable {
    [self fetchAllStreams];
}

#pragma mark - Parse methods

- (void)fetchAllStreams
{
    PFQuery *query = [PFQuery queryWithClassName:@"LiveStream"];
    [query orderByDescending:@"createdAt"];
//    [query whereKey:@"isLive" equalTo:@"TRUE"];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        [query whereKey:@"location" nearGeoPoint:geoPoint withinKilometers:MAX_SEARCH_DISTANCE];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.liveStreamsArray = [objects mutableCopy];
                NSLog(@"\n\n\n liveStreamsNum: %lu\n\n\n", (unsigned long)[objects count]);
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
            }else{
                NSLog(@"fetch failed");
            }
        }];
    }];
}

#pragma mark - Alert view

- (IBAction)startBroadcast:(UIBarButtonItem *)sender {
    [self askForStreamName];
}

- (IBAction)logOut:(id)sender {
    [PFUser logOut];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate toggleLogin];
}

- (void)askForStreamName{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Name" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Dive in!", nil] ;
    alertView.tag = 2;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        
        if(alertTextField.text.length == 0){
            [self alertWithTitle:@"Oops" andMessage:@"Stream name was empty 😭"];
        }else{
            [alertTextField resignFirstResponder];
            self.streamName = [alertTextField.text mutableCopy];
            [self performSegueWithIdentifier:@"StartStreaming" sender:nil];
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.liveStreamsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LiveCell";
    LiveStreamCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    PFObject *liveStream = [self.liveStreamsArray objectAtIndex:indexPath.row];
    [self setupCellStyle:cell];
    [self populateCell:cell withLiveStream:liveStream AtIndexPathRow:indexPath.row];
//    [self downloadImageToCell:cell withPost:post andTV:tableView andIndexPath:indexPath];

    return cell;
}

- (void)setupCellStyle:(LiveStreamCell *)cell{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.photo.layer.cornerRadius = 30.0;
    cell.photo.backgroundColor = [self getLightBlue];
}

- (void)populateCell:(LiveStreamCell *)cell withLiveStream:(PFObject *)liveStream AtIndexPathRow:(NSInteger)indexpath_row
{
    PFUser *user = liveStream[@"user"];
    [user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        NSString *userName = [NSString stringWithFormat:@"%@ %@", user[@"firstName"], user[@"lastName"]];
        int numViewers = [liveStream[@"numViewers"] intValue];
        cell.title.text = liveStream[@"streamName"];
        cell.numViewsAndBroadcasterName.text =[NSString stringWithFormat:@"by %@ ・ %d viewers",userName, numViewers];
    }];
//    cell.timeLabel.text = [self getTimeDifferenceFromDatePosted:[post createdAt]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.watchLiveStream = [self.liveStreamsArray objectAtIndex:indexPath.row];
    NSString *isLive =self.watchLiveStream[@"isLive"];
    if([isLive isEqualToString:@"TRUE"]) [self performSegueWithIdentifier:@"StartWatching" sender:nil];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = @"LIVE";
            break;
        case 1:
            sectionName = @"HIGHLIGHTS";
            break;
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *v = (UITableViewHeaderFooterView *)view;
    v.backgroundView.backgroundColor = [self getSpaceGrey];
    UITableViewHeaderFooterView *headerIndexText = (UITableViewHeaderFooterView *)view;
    [headerIndexText.textLabel setTextColor:[UIColor whiteColor]];
}

- (UIColor *)getLightBlue{ return [[UIColor alloc] initWithRed:21.0/255.0 green:153.0/255.0 blue:169.0/255.0 alpha:1];}
- (UIColor *)getHeaderGrey{ return [[UIColor alloc] initWithRed:23.0/255.0 green:28.0/255.0 blue:33.0/255.0 alpha:1];}
- (UIColor *)getSpaceGrey{ return [[UIColor alloc] initWithRed:32.0/255.0 green:37.0/255.0 blue:42.0/255.0 alpha:1];}


- (NSString *)removeAllNonAlphaNumeric:(NSMutableString *)word
{
    NSMutableCharacterSet *charactersToKeep = [NSMutableCharacterSet alphanumericCharacterSet];
    NSCharacterSet *charactersToRemove = [charactersToKeep invertedSet];
    NSString *nonAlphaNumericStr = [[word componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@"" ];
    return nonAlphaNumericStr;
}

-(void)alertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}


#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"StartStreaming"]) {
        BroadcastVC* vc = [segue destinationViewController];
        vc.streamName = self.streamName;
        vc.streamFileName = [self removeAllNonAlphaNumeric:self.streamName];
    }
    
    if ([[segue identifier] isEqualToString:@"StartWatching"]) {
        WatchStreamVC* vc = [segue destinationViewController];
        vc.liveStream = self.watchLiveStream;
    }
}


@end
