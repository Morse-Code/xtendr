//
//  XTFollowListViewController.h
//  xtendr
//
//  Created by Tony Million on 22/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XTFollowListViewController : UITableViewController

// if showFollowers is false then it'll show who you're FOLLOWING
-(id)initWithUserID:(NSString*)userID showFollowers:(BOOL)showFollowers;

@end
