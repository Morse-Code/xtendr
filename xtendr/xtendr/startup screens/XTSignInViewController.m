//
//  XTSignInViewController.m
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTSignInViewController.h"

#import "XTProfileController.h"

@interface XTSignInViewController () <UIWebViewDelegate>

@property(weak) IBOutlet UIWebView			*webView;

@end

@implementation XTSignInViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.title = NSLocalizedString(@"Sign In", @"");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancel:)];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(validityChanged:) name:kXTProfileValidityChangedNotification object:nil];
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


    NSString *redirectURI		= @"xtendr://authcomplete";
    NSString *scopes			= @"stream write_post follow messages";
    NSString *authURLstring = [NSString stringWithFormat:@"https://alpha.app.net/oauth/authenticate?adnview=appstore&client_id=%@&response_type=token&redirect_uri=%@&scope=%@", kANAPIClientID, redirectURI, scopes];
    NSURL *authURL = [NSURL URLWithString:[authURLstring stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];


	NSMutableURLRequest * req = [[NSMutableURLRequest alloc] initWithURL:authURL];

	[self.webView loadRequest:req];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	DLog(@"shouldStartLoadWithRequest: %@", request.URL);

	if([request.URL.absoluteString hasPrefix:@"xtendr"])
	{
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	}

	return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	DLog(@"didFailLoadWithError:%@", error);
}

-(IBAction)cancel:(id)sender
{
    [self.parentViewController dismissViewControllerAnimated:YES
                                                  completion:^{}];
}

-(void)validityChanged:(NSNotification*)note
{
	if([XTProfileController sharedInstance].isSessionValid)
	{
		[self.parentViewController dismissViewControllerAnimated:YES completion:nil];
	}
}
@end
