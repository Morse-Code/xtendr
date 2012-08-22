//
//  XTProfileFollowCell.m
//  xtendr
//
//  Created by Tony Million on 22/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTProfileFollowCell.h"

@interface XTProfileFollowCell ()

@property(weak) IBOutlet UIImageView	*followImageView;
@property(weak) IBOutlet UILabel		*followTextLabel;

@end

@implementation XTProfileFollowCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setFollowingCount:(NSNumber*)followingCount
{
	//TODO: set icon
	self.followTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Following %@ users", @""), followingCount];
}

-(void)setFollowedCount:(NSNumber*)followedCount
{
	//TODO: set icon
	self.followTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Followed by %@ users", @""), followedCount];
}


@end
