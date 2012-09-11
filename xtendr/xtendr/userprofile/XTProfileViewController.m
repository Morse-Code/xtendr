//
//  XTProfileViewController.m
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTProfileViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "XTUserController.h"
#import	"XTImageObject.h"

#import	"UIImageView+NetworkLoad.h"

#import "User+coolstuff.h"

#import "XTPostController.h"
#import "XTTimelineCell.h"

#import "XTNewPostViewController.h"

#import "XTProfileController.h"

#import "XTProfileBioCell.h"
#import "XTProfileFollowCell.h"


#import "XTFollowListViewController.h"

#import "XTConversationViewController.h"

#import "TimeScroller.h"


@interface XTProfileViewController () <NSFetchedResultsControllerDelegate, TimeScrollerDelegate>

@property(weak) IBOutlet UIView					*headerView;
@property(weak) IBOutlet UIImageView			*headerBackgroundImageView;
@property(weak) IBOutlet UIImageView			*userImageView;
@property(weak) IBOutlet UILabel				*userNameLabel;
@property(weak) IBOutlet UILabel				*userPostCountLabel;
@property(weak) IBOutlet UILabel				*followersLabel;
@property(weak) IBOutlet UILabel				*followingLabel;
@property(weak) IBOutlet UILabel				*userBiogLabel;

@property(weak) IBOutlet UIButton				*followUnfollowButton;
@property(weak) IBOutlet UIButton				*muteUnmuteButton;

@property(copy) NSString						*internalUserID;
@property(strong) NSFetchedResultsController	*userfetchedResultsController;

@property(strong) NSFetchedResultsController	*postsFetchedResultsController;

@property(strong) TimeScroller					*timeScroller;

@end

@implementation XTProfileViewController

-(void)setupHeader
{
	DLog(@"set up header");

	User * tempUser;

	if(self.userfetchedResultsController.fetchedObjects.count)
	{
		tempUser = [self.userfetchedResultsController.fetchedObjects lastObject];

		self.userNameLabel.text = [NSString stringWithFormat:@"%@ (%@)", tempUser.username, tempUser.id];

		self.userPostCountLabel.text = [NSString stringWithFormat:@"%@ posts", tempUser.postcount];

		self.userBiogLabel.text = tempUser.desc_text;

		XTImageObject * cover = tempUser.cover;
		if(cover)
		{
			[self.headerBackgroundImageView loadFromURL:cover.url
									   placeholderImage:[UIImage imageNamed:@"brownlinen"]
											  fromCache:(TMDiskCache*)[XTAppDelegate sharedInstance].userCoverArtCache];
		}

		XTImageObject * avatar = tempUser.avatar;
		if(avatar)
		{
			[self.userImageView loadFromURL:avatar.url
						   placeholderImage:[UIImage imageNamed:@"unknown"]
								  fromCache:(TMDiskCache*)[XTAppDelegate sharedInstance].userProfilePicCache];
		}

		if([tempUser.you_follow boolValue])
		{
			[self.followUnfollowButton setTitle:NSLocalizedString(@"Unfollow", @"")
									   forState:UIControlStateNormal];
		}
		else
		{
			[self.followUnfollowButton setTitle:NSLocalizedString(@"Follow", @"")
									   forState:UIControlStateNormal];
		}

		if([tempUser.you_muted boolValue])
		{
			[self.muteUnmuteButton setTitle:NSLocalizedString(@"Unmute", @"")
								   forState:UIControlStateNormal];
		}
		else
		{
			[self.muteUnmuteButton setTitle:NSLocalizedString(@"mute", @"")
								   forState:UIControlStateNormal];
		}

		if([[XTProfileController sharedInstance].profileUser.id isEqual:tempUser.id])
		{
			//THIS IS US!!!
			self.followUnfollowButton.hidden = YES;
		}
		else
		{
			self.followUnfollowButton.hidden = NO;
		}
	}
	else
	{
		self.userNameLabel.text = NSLocalizedString(@"Getting details..", @"");
		[self.headerBackgroundImageView loadFromURL:nil
								   placeholderImage:[UIImage imageNamed:@"brownlinen"]
										  fromCache:(TMDiskCache*)[XTAppDelegate sharedInstance].userCoverArtCache];

	}

}

-(id)initWithUserID:(NSString*)userid
{
	self = [super initWithStyle:UITableViewStylePlain];
	if(self)
	{
		self.title = NSLocalizedString(@"Profile", @"");
		self.tabBarItem.tag = PROFILE_VIEW_TAG;

		self.internalUserID = userid;
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.timeScroller = [[TimeScroller alloc] initWithDelegate:self];

	self.tableView.backgroundColor	= [UIColor colorWithPatternImage:[UIImage imageNamed:@"furley_bg"]];
	self.tableView.separatorStyle	= UITableViewCellSeparatorStyleNone;

	[self.tableView registerNib:[UINib nibWithNibName:@"XTTimelineCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"timelineCell"];

	[self.tableView registerNib:[UINib nibWithNibName:@"XTProfileBioCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"bioCell"];

	[self.tableView registerNib:[UINib nibWithNibName:@"XTProfileFollowCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"followCell"];

	[[NSBundle mainBundle] loadNibNamed:@"XTProfileHeader"
                                  owner:self
                                options:nil];

	CALayer * l = self.userImageView.layer;

    l.masksToBounds = YES;
    l.cornerRadius  = 7;
    l.borderWidth   = 1;
    l.borderColor   = [UIColor darkGrayColor].CGColor;


	self.tableView.tableHeaderView = self.headerView;


	// Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
                                              inManagedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext];

    [fetchRequest setEntity:entity];

	// limit to those entities to this ID
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", self.internalUserID];
    [fetchRequest setPredicate:predicate];

	DLog(@"predicate: %@", predicate);

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

	// we only want one object!
	[fetchRequest setFetchLimit:1];

    // Create and initialize the fetchedResultsController.
    self.userfetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																			managedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext
																			  sectionNameKeyPath:nil /* one section */
																					   cacheName:nil];

    self.userfetchedResultsController.delegate = self;

    NSError *error;
    [self.userfetchedResultsController performFetch:&error];

	[self setupHeader];




	// Create and configure a fetch request.
    NSFetchRequest *postsfetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *postentity = [NSEntityDescription entityForName:@"Post"
												  inManagedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext];

    [postsfetchRequest setEntity:postentity];

	// limit to those entities to this ID
    NSPredicate *postpredicate = [NSPredicate predicateWithFormat:@"userid == %@ AND is_deleted == %@", self.internalUserID, [NSNumber numberWithBool:NO]];
    [postsfetchRequest setPredicate:postpredicate];

    NSSortDescriptor *postsortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid" ascending:NO];
    NSArray *postsortDescriptors = [[NSArray alloc] initWithObjects:postsortDescriptor, nil];
    [postsfetchRequest setSortDescriptors:postsortDescriptors];

	// we only want one object!
	[postsfetchRequest setFetchLimit:20];

    // Create and initialize the fetchedResultsController.
    self.postsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:postsfetchRequest
																			 managedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext
																			   sectionNameKeyPath:nil /* one section */
																						cacheName:nil];

    self.postsFetchedResultsController.delegate = self;

    NSError *postserror;
    [self.postsFetchedResultsController performFetch:&postserror];


}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self downloadUserDetails:self.internalUserID];
	[self downloadPostsForUser:self.internalUserID];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1+self.postsFetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	if(section == 0)
	{
		return 3;
	}
	
	if(section == 1)
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [self.postsFetchedResultsController.sections objectAtIndex:0];
		return [sectionInfo numberOfObjects];
	}

	return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		User * tempUser;
		if(self.userfetchedResultsController.fetchedObjects.count)
			tempUser = [self.userfetchedResultsController.fetchedObjects lastObject];

		if(indexPath.row == 0)
		{
			//calculate
			return MAX([XTProfileBioCell heightForText:tempUser.desc_text], 48);
		}
		else
			return 48;
	}

	if(indexPath.section == 1)
	{
		Post * post = [self.postsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
		return [XTTimelineCell cellHeightForPost:post];
	}

	return 60;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		User * tempUser;
		if(self.userfetchedResultsController.fetchedObjects.count)
			tempUser = [self.userfetchedResultsController.fetchedObjects lastObject];

		if(indexPath.row == 0)
		{
			XTProfileBioCell * bioCell = [tableView dequeueReusableCellWithIdentifier:@"bioCell"];

			if(tempUser)
				bioCell.bioLabel.text = tempUser.desc_text;
			else
				bioCell.bioLabel.text = @"";

			return bioCell;
		}

		if(indexPath.row == 1)
		{
			XTProfileFollowCell * followingCell = [tableView dequeueReusableCellWithIdentifier:@"followCell"];

			[followingCell setFollowingCount:tempUser.following];

			return followingCell;
		}

		if(indexPath.row == 2)
		{
			XTProfileFollowCell * followerCell = [tableView dequeueReusableCellWithIdentifier:@"followCell"];

			[followerCell setFollowedCount:tempUser.followers];

			return followerCell;
		}

	}

	if(indexPath.section == 1)
	{
		Post * post = [self.postsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];

		XTTimelineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timelineCell"];

		cell.post = post;

		cell.quickReplyBlock = ^(Post * post)
		{
			XTNewPostViewController * npvc = [[XTNewPostViewController alloc] init];
			npvc.replyToPost = post;

			[self presentViewController:[[UINavigationController alloc] initWithRootViewController:npvc]
							   animated:YES
							 completion:nil];
		};

		return cell;
	}
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		if(indexPath.row == 1)
		{
			// show following
			XTFollowListViewController * flvc = [[XTFollowListViewController alloc] initWithUserID:self.internalUserID showFollowers:NO];
			[self.navigationController pushViewController:flvc animated:YES];
		}
		if(indexPath.row == 2)
		{
			//show followers
			XTFollowListViewController * flvc = [[XTFollowListViewController alloc] initWithUserID:self.internalUserID showFollowers:YES];
			[self.navigationController pushViewController:flvc animated:YES];
		}
	}
	
	if(indexPath.section == 1)
	{
		Post * post = [self.postsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
		XTConversationViewController * cvc = [[XTConversationViewController alloc] initWithPost:post];

		[self.navigationController pushViewController:cvc animated:YES];

	}
}

-(void)downloadUserDetails:(NSString*)userID
{
	[[XTHTTPClient sharedClient] getPath:[NSString stringWithFormat:@"users/%@", self.internalUserID]
							  parameters:nil
								 success:^(TMHTTPRequest *operation, id responseObject) {
									 DLog(@"got user: %@", responseObject);

									 if(responseObject && [responseObject isKindOfClass:[NSDictionary class]])
									 {
										 [[XTUserController sharedInstance] addUser:responseObject];
									 }
								 }
								 failure:^(TMHTTPRequest *operation, NSError *error) {

								 }];
}

-(void)downloadPostsForUser:(NSString*)userID
{
	//https://alpha-api.app.net/stream/0/users/[user_id]/posts

	[[XTHTTPClient sharedClient] getPath:[NSString stringWithFormat:@"users/%@/posts", self.internalUserID]
							  parameters:nil
								 success:^(TMHTTPRequest *operation, id responseObject) {
									 DLog(@"got posts: %@", responseObject);

									 if(responseObject && [responseObject isKindOfClass:[NSArray class]])
									 {
										 NSArray * temp = responseObject;
										 if(temp && temp.count)
										 {
											 [[XTPostController sharedInstance] addPostArray:responseObject
																				fromMyStream:NO
																				fromMentions:NO];

											 //self.lastID = [[temp lastObject] objectForKey:@"id"];
											 //self.lastLoadCount += temp.count;
										 }
									 }


								 }
								 failure:^(TMHTTPRequest *operation, NSError *error) {

								 }];

}

#pragma mark - fetched results stuff

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	DLog(@"controllerWillChangeContent");
	if(controller == self.postsFetchedResultsController)
	{
		[self.tableView beginUpdates];
	}
	else
	{

	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	DLog(@"controllerDidChangeContent");
	if(controller == self.postsFetchedResultsController)
	{
		[self.tableView endUpdates];
	}
	else
	{
		[self setupHeader];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	DLog(@"didChangeObject");
	if(controller == self.userfetchedResultsController)
	{
		[self setupHeader];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
		return;
	}

	// override the default to put the details in section 0
	// I wish apple actually made this easy :(
	indexPath		= [NSIndexPath indexPathForRow:indexPath.row inSection:1];
	newIndexPath	= [NSIndexPath indexPathForRow:newIndexPath.row inSection:1];

	//ok now we do the funky table stuff!
	UITableView *tableView = self.tableView;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationNone];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeMove:
			[tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }

}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(IBAction)followUnfollow:(id)sender
{
	User * tempUser;

	if(!self.userfetchedResultsController.fetchedObjects.count)
		return;

	tempUser = [self.userfetchedResultsController.fetchedObjects lastObject];

	self.followUnfollowButton.enabled = NO;

	if([tempUser.you_follow boolValue])
	{
		//DO DELETE FOLLOW
		[[XTHTTPClient sharedClient] deletePath:[NSString stringWithFormat:@"users/%@/follow", self.internalUserID]
									 parameters:nil
										success:^(TMHTTPRequest *operation, id responseObject) {
											DLog(@"UNFOLLOW SUCCESS: %@", responseObject);

											if(responseObject && [responseObject isKindOfClass:[NSDictionary class]])
											{
												[[XTUserController sharedInstance] addUser:responseObject];
											}

											self.followUnfollowButton.enabled = YES;
										}
										failure:^(TMHTTPRequest *operation, NSError *error) {
											self.followUnfollowButton.enabled = YES;
										}];
	}
	else
	{
		//DO POST FOLLOW

		[[XTHTTPClient sharedClient] postPath:[NSString stringWithFormat:@"users/%@/follow", self.internalUserID]
								   parameters:nil
									  success:^(TMHTTPRequest *operation, id responseObject) {
										  DLog(@"FOLLOW SUCCESS: %@", responseObject);

										  if(responseObject && [responseObject isKindOfClass:[NSDictionary class]])
										  {
											  [[XTUserController sharedInstance] addUser:responseObject];
										  }
										  self.followUnfollowButton.enabled = YES;
									  }
									  failure:^(TMHTTPRequest *operation, NSError *error) {										  
										  self.followUnfollowButton.enabled = YES;
									  }];
	}
}

#pragma mark - timedelegate thing
//You should return your UITableView here
- (UITableView *)tableViewForTimeScroller:(TimeScroller *)timeScroller
{
    return self.tableView;
}

//You should return an NSDate related to the UITableViewCell given. This will be
//the date displayed when the TimeScroller is above that cell.
- (NSDate *)dateForCell:(UITableViewCell *)cell
{
	if(!self.postsFetchedResultsController.fetchedObjects || self.postsFetchedResultsController.fetchedObjects.count == 0)
		return nil;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	DLog(@"indexPath = %@", indexPath);
	if(indexPath.section == 1)
	{
		Post *post = [self.postsFetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
		NSDate *date = [post created_at];

		return date;
	}

	return nil;
}

#pragma mark - View Scrolling header thing

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_timeScroller scrollViewWillBeginDragging];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        [_timeScroller scrollViewDidEndDecelerating];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_timeScroller scrollViewDidEndDecelerating];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if(scrollView.contentOffset.y < 0)
	{
		CGFloat extra = abs(scrollView.contentOffset.y);

		CGRect rect = self.headerView.frame;
		rect.origin.y = MIN(0, scrollView.contentOffset.y);
		rect.size.height = 170 + extra;
		self.headerView.frame = rect;
	}

    [_timeScroller scrollViewDidScroll];
}

@end
