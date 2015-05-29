//
//  WatchStreamVC.h
//  Dive
//
//  Created by Kevin Yang on 3/11/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface WatchStreamVC : UIViewController

@property (nonatomic, strong) PFObject *liveStream;

@end
