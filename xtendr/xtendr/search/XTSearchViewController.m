//
//  XTSearchViewController.m
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTSearchViewController.h"

#import "XTHTTPClient.h"

#import "XTTimelineCell.h"

#import "XTProfileController.h"
#import "XTNewPostViewController.h"
#import "XTProfileViewController.h"
#import "XTPostController.h"


#define kResultsTypePosts		(0)
#define kResultsTypeUsers		(1)

// Scopebar constants
#define kSearchByHashTag		0
#define kSearchByUser				1
#define kSearchByPost				2

@interface XTSearchViewController () <UISearchBarDelegate>

@property(strong) UISearchBar					*searchBar;

@property(strong) NSArray						*resultArray;
@property(assign) NSUInteger					resultsType;

@property(strong) TMHTTPClient					*adnClient;

@end

@implementation XTSearchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
		self.title = NSLocalizedString(@"Search", @"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.tableView.backgroundColor	= [UIColor colorWithPatternImage:[UIImage imageNamed:@"furley_bg"]];
	self.tableView.separatorStyle	= UITableViewCellSeparatorStyleNone;

	[self.tableView registerNib:[UINib nibWithNibName:@"XTTimelineCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"timelineCell"];

	self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
	self.searchBar.placeholder			= NSLocalizedString(@"Search app.net", @"");
	self.searchBar.delegate				= self;
	self.searchBar.showsScopeBar		= YES;
	self.searchBar.scopeButtonTitles	= [NSArray arrayWithObjects:@"Hashtags", @"Users", @"Posts", nil];
	[self.searchBar sizeToFit];

    self.tableView.tableHeaderView = self.searchBar;

	self.adnClient = [[TMHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.nanek.net/"]];
	[self.adnClient setDefaultHeader:@"Authorization"
							   value:@"Basic bHlHS2xTNXFsblNEOmx5R0tsUzVxbG5TRA=="];
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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.resultArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.resultsType == kResultsTypePosts)
	{
		Post * post = [self.resultArray objectAtIndex:indexPath.row];


		return [XTTimelineCell cellHeightForPost:post];
	}
	else if(self.resultsType == kResultsTypeUsers)
	{
		return 56;
	}

	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.resultsType == kResultsTypePosts)
	{
		Post * post = [self.resultArray objectAtIndex:indexPath.row];

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
	else if(self.resultsType == kResultsTypeUsers)
	{
		static NSString *CellIdentifier = @"Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

		// Configure the cell...
		if(!cell)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
										  reuseIdentifier:CellIdentifier];
		}
		cell.textLabel.text = @"User";
		return cell;
	}
	else
	{
	}
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self.view endEditing:YES];
}

#pragma mark - search delegate stuff



- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	DLog(@"should search %d", searchBar.selectedScopeButtonIndex);
	[searchBar resignFirstResponder];

	if(searchBar.selectedScopeButtonIndex == kSearchByHashTag)
	{
		//https://alpha-api.app.net/stream/0/posts/tag/[hashtag]

		[[XTHTTPClient sharedClient] getPath:[NSString stringWithFormat:@"posts/tag/%@", searchBar.text]
								  parameters:nil
									 success:^(TMHTTPRequest *operation, id responseObject) {
										 DLog(@"Hashtag search: %@", responseObject);

										 [[XTPostController sharedInstance] addPostArray:responseObject fromMyStream:NO fromMentions:NO];

										 NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[responseObject count]];
										 for (NSDictionary * postDict in responseObject) {
											 NSString *postID = [postDict objectForKey:@"id"];
											 [ids addObject:[NSNumber numberWithLongLong:[postID longLongValue]]];
										 }

										 DLog(@"id = %@", ids);


										 NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Post"];

										 NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid"
																										ascending:NO];

										 NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
										 [request setSortDescriptors:sortDescriptors];

										 
										 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"intid IN %@", ids];
										 [request setPredicate:predicate];

										 NSError *error;
										 //so if the object isn't in core data it returns a 0 length array
										 // at which point lastObject returns nil
										 // yay
										 self.resultArray = [[XTAppDelegate sharedInstance].managedObjectContext executeFetchRequest:request
																															   error:&error];

										 DLog(@"results = %@", self.resultArray);


										 self.resultsType = kResultsTypePosts;
										 [self.tableView reloadData];
									 }
									 failure:^(TMHTTPRequest *operation, NSError *error) {
										 
									 }];
	}
	else if(searchBar.selectedScopeButtonIndex == kSearchByUser)
	{
		//bHlHS2xTNXFsblNEOmx5R0tsUzVxbG5TRA==
		//https://api.nanek.net/users?q=query

		[self.adnClient getPath:@"users"
					 parameters:[NSDictionary dictionaryWithObject:searchBar.text forKey:@"q"]
						success:^(TMHTTPRequest *operation, id responseObject) {
							DLog(@"user search SUCCESS: %@", responseObject);

							NSArray * results = [responseObject objectForKey:@"results"];

							NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[results count]];
							for (NSDictionary * postDict in results) {
								NSString *postID = [postDict objectForKey:@"id"];
								[ids addObject:[NSNumber numberWithLongLong:[postID longLongValue]]];
							}

							DLog(@"id = %@", ids);


							NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

							NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid"
																						   ascending:NO];

							NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
							[request setSortDescriptors:sortDescriptors];


							NSPredicate *predicate = [NSPredicate predicateWithFormat:@"intid IN %@", ids];
							[request setPredicate:predicate];

							NSError *error;
							//so if the object isn't in core data it returns a 0 length array
							// at which point lastObject returns nil
							// yay
							self.resultArray = [[XTAppDelegate sharedInstance].managedObjectContext executeFetchRequest:request
																												  error:&error];

							DLog(@"results = %@", self.resultArray);


							self.resultsType = kResultsTypeUsers;
							[self.tableView reloadData];
						}
						failure:^(TMHTTPRequest *operation, NSError *error) {
							DLog(@"user search FAIL: %@", operation.responseString);
						}];
	}
	else if(searchBar.selectedScopeButtonIndex == kSearchByPost)
	{
		//https://api.nanek.net/search?q=query

		[self.adnClient getPath:@"search"
					 parameters:[NSDictionary dictionaryWithObject:searchBar.text forKey:@"q"]
						success:^(TMHTTPRequest *operation, id responseObject) {
							DLog(@"user search SUCCESS: %@", responseObject);
							
							NSArray * results = [responseObject objectForKey:@"results"];

							[[XTPostController sharedInstance] addPostArray:results fromMyStream:NO fromMentions:NO];



							NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[results count]];
							for (NSDictionary * postDict in results) {
								NSString *postID = [postDict objectForKey:@"id"];
								[ids addObject:[NSNumber numberWithLongLong:[postID longLongValue]]];
							}

							DLog(@"id = %@", ids);


							NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:@"Post"];

							NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid"
																						   ascending:NO];

							NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
							[request setSortDescriptors:sortDescriptors];


							NSPredicate *predicate = [NSPredicate predicateWithFormat:@"intid IN %@", ids];
							[request setPredicate:predicate];

							NSError *error;
							//so if the object isn't in core data it returns a 0 length array
							// at which point lastObject returns nil
							// yay
							self.resultArray = [[XTAppDelegate sharedInstance].managedObjectContext executeFetchRequest:request
																												  error:&error];

							DLog(@"results = %@", self.resultArray);
							
							
							self.resultsType = kResultsTypePosts;
							[self.tableView reloadData];
						}
						failure:^(TMHTTPRequest *operation, NSError *error) {
							DLog(@"user search FAIL: %@", operation.responseString);
						}];

	}
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	[self searchBarSearchButtonClicked:searchBar];
}

@end
