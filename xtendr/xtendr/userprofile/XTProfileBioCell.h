//
//  XTProfileBioCell.h
//  xtendr
//
//  Created by Tony Million on 22/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XTProfileBioCell : UITableViewCell

+(CGFloat)heightForText:(NSString*)text;

@property(weak) IBOutlet UILabel *bioLabel;


@end
