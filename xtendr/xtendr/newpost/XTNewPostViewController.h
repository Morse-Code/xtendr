//
//  XTNewPostViewController.h
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XTNewPostViewController : UITableViewController

@property(strong) Post		*replyToPost;

@property(strong) NSString	*prepopulateText;

@property(strong) UIImage	*imageAttachment;


@end
