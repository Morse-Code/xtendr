//
//  XTTimelineCell.h
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Post.h"

//typedef void (^faceTapBlock)(Post *post);

typedef void (^quickReplyBlock)(Post *post);

@interface XTTimelineCell : UITableViewCell

//@property(nonatomic, copy) faceTapBlock		faceTapBlock;
@property(nonatomic, copy) quickReplyBlock	quickReplyBlock;
@property(nonatomic, strong) Post			*post;

+(CGFloat)cellHeightForPost:(Post*)post;
-(void)setPost:(Post*)post;


@end
