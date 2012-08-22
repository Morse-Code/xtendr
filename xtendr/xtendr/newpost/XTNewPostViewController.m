//
//  XTNewPostViewController.m
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTNewPostViewController.h"

#import "XTNewPostCell.h"

#import "XTHTTPClient.h"

#import "XTProfileController.h"

#import "TMImgurUploader.h"

@interface XTNewPostViewController () <UITextViewDelegate>

@property(strong) XTNewPostCell			*theCell;
@property(assign) CGFloat               textHeight;

@end

@implementation XTNewPostViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
		self.title = NSLocalizedString(@"New Post", @"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.tableView.backgroundColor	= [UIColor colorWithPatternImage:[UIImage imageNamed:@"timelineback"]];
	self.tableView.separatorStyle	= UITableViewCellSeparatorStyleNone;

	[self.tableView registerNib:[UINib nibWithNibName:@"XTNewPostCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"XTNewPostCell"];

    self.theCell = [self.tableView dequeueReusableCellWithIdentifier:@"XTNewPostCell"];

	if(self.replyToPost)
	{
		self.theCell.replyToLabel.hidden = NO;
	}
	else
	{
		self.theCell.replyToLabel.hidden = YES;
	}

	//self.theCell.finalDelegate = self;
    //self.theCell.user = [ZZProfileController sharedInstance].user;

    self.theCell.textView.delegate = self;


	if(self.imageAttachment)
		self.theCell.imageAttachmentView.image = self.imageAttachment;

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];

	// add picture button!
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Post", @"")
																			  style:UIBarButtonItemStyleDone                                                                                            target:self
																			 action:@selector(save:)];

	self.navigationItem.rightBarButtonItem.enabled = NO;

	if(self.replyToPost)
	{
		NSMutableString * startText = [[NSMutableString alloc] init];

		[startText appendFormat:@"@%@ ", self.replyToPost.user.username];

		for (XTMention * mention in self.replyToPost.mentions) {
			if([mention.id isEqualToString:[XTProfileController sharedInstance].profileUser.id])
				continue;

			[startText appendFormat:@"@%@ ", mention.name];
		}

		self.theCell.textView.text = startText;
		[self textViewDidChange:self.theCell.textView];
	}
	else if(self.prepopulateText)
	{
		self.theCell.textView.text = self.prepopulateText;
		[self textViewDidChange:self.theCell.textView];
	}

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self.navigationController setNavigationBarHidden:NO animated:YES];

	[self.theCell.textView becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize requiredSize = self.theCell.textView.contentSize;
    return MAX(requiredSize.height+40, 200);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return self.theCell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - UITextViewDelegateness

- (void)tableViewNeedsToUpdateHeight
{
    BOOL animationsEnabled = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:animationsEnabled];

	NSIndexPath* ipath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView scrollToRowAtIndexPath:ipath
						  atScrollPosition:UITableViewScrollPositionBottom
								  animated:YES];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.text.length)
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }

	int charsleft = 256 - textView.text.length;

	if(self.imageAttachment)
		charsleft -= 30;

	if(charsleft>0)
	{
		self.theCell.charsLeftLabel.textColor = [UIColor lightGrayColor];
	}
	else
	{
		self.theCell.charsLeftLabel.textColor = [UIColor redColor];
	}

	self.theCell.charsLeftLabel.text = [NSString stringWithFormat:@"%d", charsleft];

    CGFloat newTextHeight = [textView contentSize].height;

    if(newTextHeight != self.textHeight)
    {
        self.textHeight = newTextHeight;
        [self tableViewNeedsToUpdateHeight];
    }
}

#pragma mark - IBActions

-(IBAction)cancel:(id)sender
{
	[self.parentViewController dismissViewControllerAnimated:YES
                                                  completion:^{

                                                  }];
}

-(void)actuallyDoPostWithText:(NSString*)text andAnnotation:(NSDictionary*)annotation
{
	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithCapacity:2];

	[params setObject:text
			   forKey:@"text"];

	if(self.replyToPost)
	{
		[params setObject:self.replyToPost.id
				   forKey:@"reply_to"];
	}

	/*
	if(annotation)
	{
		NSData * jsonData = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObject:annotation forKey:@"annotation"]
															options:0
															  error:nil];

		if(jsonData)
		{
			NSString * temp = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
			if(temp)
			{
				DLog(@"temp = %@", temp);
				[params setObject:[temp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
						   forKey:@"annotations"];
			}
		}
	}
	 */


	[[XTHTTPClient sharedClient] postPath:@"posts"
							   parameters:params
								  success:^(TMHTTPRequest *operation, id responseObject) {

									  DLog(@"POST SUCCESS: %@", responseObject);

									  [self.parentViewController dismissViewControllerAnimated:YES
																					completion:^{

																					}];
								  }
								  failure:^(TMHTTPRequest *operation, NSError *error) {
									  DLog(@"ERROR: %@, %@", operation.responseString, error);
									  self.navigationItem.rightBarButtonItem.enabled = YES;
									  self.theCell.textView.userInteractionEnabled = NO;
								  }];


}

-(IBAction)save:(id)sender
{
	self.navigationItem.rightBarButtonItem.enabled	= NO;
	self.theCell.textView.userInteractionEnabled	= NO;

	NSString *text = self.theCell.textView.text;




	NSMutableDictionary *annotation = [NSMutableDictionary dictionaryWithCapacity:2];
	

	NSMutableDictionary *xtendrDict = [NSMutableDictionary dictionaryWithCapacity:2];

	[annotation setObject:xtendrDict forKey:@"xtendr"];
	//TODO: we can geotag here!

	if(self.imageAttachment)
	{
		[xtendrDict setObject:@"photo" forKey:@"posttype"];
		
		[[TMImgurUploader sharedInstance] uploadImage:self.imageAttachment
										finishedBlock:^(NSDictionary *result, NSError *error) {
											DLog(@"reult = %@, error = %@", result, error);
											if(result)
											{
												NSDictionary * upload = [result objectForKey:@"upload"];
												
												NSDictionary * image = [upload objectForKey:@"image"];
												
												NSDictionary * links = [upload objectForKey:@"links"];

												NSString * original = [links objectForKey:@"original"];

												NSString * blockString = [text copy];

												if(blockString && blockString.length)
												{
													blockString = [text stringByAppendingString:@" "];
												}

												blockString = [text stringByAppendingFormat:@" %@", original];


												NSMutableDictionary * photo = [NSMutableDictionary dictionaryWithCapacity:3];
												[photo setObject:[image objectForKey:@"width"]
														  forKey:@"width"];
												[photo setObject:[image objectForKey:@"height"]
														  forKey:@"height"];
												[photo setObject:original
														  forKey:@"url"];

												[xtendrDict setObject:photo forKey:@"photo"];



												[self actuallyDoPostWithText:blockString andAnnotation:annotation];
											}
										}];

	}
	else
	{
		[xtendrDict setObject:@"thought" forKey:@"posttype"];

		[self actuallyDoPostWithText:text
					   andAnnotation:annotation];

	}



/*
 image attachment
 upload =     {
 image =         {
 animated = false;
 bandwidth = 0;
 caption = "<null>";
 datetime = "2012-08-21 09:09:46";
 deletehash = rTAzJImcpixFXsv;
 hash = Z8X6L;
 height = 960;
 name = "<null>";
 size = 78040;
 title = "<null>";
 type = "image/jpeg";
 views = 0;
 width = 960;
 };
 links =         {
 "delete_page" = "http://imgur.com/delete/rTAzJImcpixFXsv";
 "imgur_page" = "http://imgur.com/Z8X6L";
 "large_thumbnail" = "http://i.imgur.com/Z8X6Ll.jpg";
 original = "http://i.imgur.com/Z8X6L.jpg";
 "small_square" = "http://i.imgur.com/Z8X6Ls.jpg";
 };
 };
 */

}

@end
