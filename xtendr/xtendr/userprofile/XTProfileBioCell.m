//
//  XTProfileBioCell.m
//  xtendr
//
//  Created by Tony Million on 22/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTProfileBioCell.h"

@implementation XTProfileBioCell

+(CGFloat)heightForText:(NSString*)text
{
	CGSize temp = [text sizeWithFont:[UIFont fontWithName:@"HelveticaNeue-Italic"
													 size:15]
				   constrainedToSize:CGSizeMake(250, CGFLOAT_MAX)
					   lineBreakMode:UILineBreakModeWordWrap];

	//+10 cos 5 at top and below!
	return temp.height+10;
}

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

@end
