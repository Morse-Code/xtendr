//
//  XTHashTagViewController.m
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTHashTagViewController.h"

#import "XTPostController.h"

#import "XTTimelineCell.h"

#import "XTProfileController.h"
#import "XTNewPostViewController.h"
#import "XTProfileViewController.h"
#import "XTPostController.h"


@interface XTHashTagViewController () <NSFetchedResultsControllerDelegate>

@property(copy) NSString	*hashTag;
@property(strong) NSArray	*idArray;

@property(strong) NSFetchedResultsController * fetchedResultsController;


@end

@implementation XTHashTagViewController

-(id)initWithHashtag:(NSString*)hashtag
{
	self = [self initWithStyle:UITableViewStylePlain];
	if(self)
	{
		self.hashTag	= hashtag;
		self.title		= [NSString stringWithFormat:@"#%@", hashtag];
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

	self.idArray = [NSArray array];


	self.tableView.backgroundColor	= [UIColor colorWithPatternImage:[UIImage imageNamed:@"furley_bg"]];
	self.tableView.separatorStyle	= UITableViewCellSeparatorStyleNone;

	[self.tableView registerNib:[UINib nibWithNibName:@"XTTimelineCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"timelineCell"];


	// Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post"
                                              inManagedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext];

    [fetchRequest setEntity:entity];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid"
																   ascending:NO];

    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];


    // limit to those entities that belong to the particular item
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id IN %@", self.idArray];
    [fetchRequest setPredicate:predicate];

    // Create and initialize the fetchedResultsController.
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext
                                                                          sectionNameKeyPath:nil /* one section */
                                                                                   cacheName:nil];

    self.fetchedResultsController.delegate = self;

    NSError *error;
    [self.fetchedResultsController performFetch:&error];

	[self dohashtagLookup];
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
	Post * post = [self.fetchedResultsController objectAtIndexPath:indexPath];

	return [XTTimelineCell cellHeightForPost:post];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Post * post = [self.fetchedResultsController objectAtIndexPath:indexPath];

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

#pragma mark - stuff

-(void)dohashtagLookup
{
	[[XTHTTPClient sharedClient] getPath:[NSString stringWithFormat:@"posts/tag/%@", self.hashTag]
							  parameters:nil
								 success:^(TMHTTPRequest *operation, id responseObject) {
									 if(responseObject && [responseObject isKindOfClass:[NSArray class]])
									 {
										 [[XTPostController sharedInstance] addPostArray:responseObject
																			fromMyStream:NO
																			fromMentions:NO];

										 NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[responseObject count]];
										 for (NSDictionary * postDict in responseObject) {
											 NSString *postID = [postDict objectForKey:@"id"];
											 [ids addObject:[NSNumber numberWithLongLong:[postID longLongValue]]];
										 }
										 self.idArray = ids;

										 // limit to those entities that belong to the particular item
										 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"intid IN %@", ids];
										 [self.fetchedResultsController.fetchRequest setPredicate:predicate];

										 self.fetchedResultsController.delegate = self;

										 NSError *error;
										 [self.fetchedResultsController performFetch:&error];
										 if(error)
										 {
											 DLog(@"error in fetch: %@", error);
										 }

										 [self.tableView reloadData];
									 }
								 }
								 failure:^(TMHTTPRequest *operation, NSError *error) {

								 }];

}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

#pragma mark - fetched results stuff

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	DLog(@"HTV controllerWillChangeContent");
    //Lets the tableview know we're potentially doing a bunch of updates.
    //[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	DLog(@"HTV controllerDidChangeContent");
    //We're finished updating the tableview's data.
    //[self.tableView endUpdates];
	[self.tableView reloadData];
}
/*
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{

    UITableView *tableView = self.tableView;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
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
*/

@end
