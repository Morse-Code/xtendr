//
//  ZZTopicPostHeaderCell.h
//  zzpostlist
//
//  Created by Tony Million on 10/06/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Post.h"

@interface ZZTopicPostHeaderCell : UITableViewCell

@property(strong, nonatomic) Post			*displayedPost;
@property(assign, nonatomic) BOOL			dividerShown;

@end
