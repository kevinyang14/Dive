//
//  LiveStreamCell.h
//  Dive
//
//  Created by Kevin Yang on 3/11/15.
//  Copyright (c) 2015 Kevin Yang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LiveStreamCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *numViewsAndBroadcasterName;
@end
