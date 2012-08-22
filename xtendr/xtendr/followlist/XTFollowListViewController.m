//
//  XTFollowListViewController.m
//  xtendr
//
//  Created by Tony Million on 22/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTFollowListViewController.h"

#import "XTUserController.h"

@interface XTFollowListViewController () <NSFetchedResultsControllerDelegate>

@property(strong) NSString						*userID;
@property(assign) BOOL							showFollowers;

@property(strong) NSFetchedResultsController	*fetchedResultsController;

@end

@implementation XTFollowListViewController

-(id)initWithUserID:(NSString*)userID showFollowers:(BOOL)showFollowers
{
	self = [self initWithStyle:UITableViewStylePlain];
	if(self)
	{
		self.userID			= userID;
		self.showFollowers	= showFollowers;

		if(showFollowers)
		{
			self.title = NSLocalizedString(@"Followers", @"");
		}
		else
		{
			self.title = NSLocalizedString(@"Following", @"");
		}

	}

	return self;
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User"
                                              inManagedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext];

    [fetchRequest setEntity:entity];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid"
																   ascending:NO];

    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];


    // limit to those entities that belong to the particular item
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"intid IN %@", [NSArray array]];
    [fetchRequest setPredicate:predicate];

    // Create and initialize the fetchedResultsController.
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext
                                                                          sectionNameKeyPath:nil /* one section */
                                                                                   cacheName:nil];

    self.fetchedResultsController.delegate = self;

    NSError *error;
    [self.fetchedResultsController performFetch:&error];

	[self getFollowList];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	User * user = [self.fetchedResultsController objectAtIndexPath:indexPath];

	return 64;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	User * user = [self.fetchedResultsController objectAtIndexPath:indexPath];

	static NSString *CellIdentifier = @"userCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	// Configure the cell...
	if(!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									  reuseIdentifier:CellIdentifier];

		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	cell.textLabel.text = user.username;


	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	User * user = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"xtendr://showuser/%@", user.id]]];
}

-(void)reloadUsersWithIDS:(NSArray*)idList
{
	// limit to those entities that belong to the particular item
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"intid IN %@", idList];
	[self.fetchedResultsController.fetchRequest setPredicate:predicate];

	self.fetchedResultsController.delegate = self;

	[NSFetchedResultsController deleteCacheWithName:self.fetchedResultsController.cacheName];

	NSError *error;
	[self.fetchedResultsController performFetch:&error];
	if(error)
	{
		DLog(@"error in fetch: %@", error);
	}

	[self.tableView reloadData];
}

-(void)getFollowList
{
	//following
	//https://alpha-api.app.net/stream/0/users/[user_id]/following

	//followers
	//https://alpha-api.app.net/stream/0/users/[user_id]/followers

	NSString * path;
	if(self.showFollowers)
	{
		path = [NSString stringWithFormat:@"users/%@/followers", self.userID];
	}
	else
	{
		path = [NSString stringWithFormat:@"users/%@/following", self.userID];
	}

	[[XTHTTPClient sharedClient] getPath:path
							  parameters:nil
								 success:^(TMHTTPRequest *operation, id responseObject) {
									 if(responseObject && [responseObject isKindOfClass:[NSArray class]])
									 {
										 [[XTUserController sharedInstance]addUsersFromArray:responseObject
																		 completion:^{
																			 NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[responseObject count]];
																			 for (NSDictionary * postDict in responseObject) {
																				 NSString *postID = [postDict objectForKey:@"id"];
																				 [ids addObject:[NSNumber numberWithLongLong:[postID longLongValue]]];
																			 }

																			 [self reloadUsersWithIDS:ids];
																		 }];
									 }
								 }
								 failure:^(TMHTTPRequest *operation, NSError *error) {
									 
								 }];
}

@end
