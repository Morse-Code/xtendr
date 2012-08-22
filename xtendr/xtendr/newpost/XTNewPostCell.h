//
//  XTNewPostCell.h
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XTNewPostCell : UITableViewCell

@property(weak) IBOutlet UITextView		*textView;
@property(weak) IBOutlet UILabel		*charsLeftLabel;

@property(weak) IBOutlet UILabel		*replyToLabel;

@property(weak) IBOutlet UIImageView	*imageAttachmentView;


@end
