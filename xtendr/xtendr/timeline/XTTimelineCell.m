//
//  XTTimelineCell.m
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTTimelineCell.h"
#import <QuartzCore/QuartzCore.h>

#import "TTTAttributedLabel.h"

#import "NSAttributedString+heightforrect.h"

#import "UIImageView+NetworkLoad.h"

#import "XTAppDelegate.h"


#define TEXT_LABEL_WIDTH	235.0

@interface XTTimelineCell () <TTTAttributedLabelDelegate>

@property(weak) IBOutlet UIImageView			*userPhoto;
@property(weak) IBOutlet UIImageView			*thoughtBubbleBackImageView;
@property(weak) IBOutlet TTTAttributedLabel		*thoughtLabel;
@property(weak) IBOutlet UILabel				*usernameLabel;
@property(weak) IBOutlet UIButton				*quickReplyButton;
@property(weak) IBOutlet UILabel				*timeAgoLabel;

@property(assign) CGFloat						labelHeight;

@end

@implementation XTTimelineCell

+(NSAttributedString*)boldString:(NSString*)string
{
    CTFontRef font      = CTFontCreateWithName(CFSTR("HelveticaNeue-Medium"), 17.0, NULL);

    NSMutableAttributedString * returnString = [[NSMutableAttributedString alloc] initWithString:string];
    [returnString addAttribute:(id)kCTFontAttributeName
                         value:(__bridge id)font
                         range:NSMakeRange(0, string.length)];

    CFRelease(font);

    return returnString;
}

+(NSAttributedString*)normalString:(NSString*)string
{
    CTFontRef font      = CTFontCreateWithName(CFSTR("HelveticaNeue"), 16.0, NULL);

    NSMutableAttributedString * returnString = [[NSMutableAttributedString alloc] initWithString:string];
    [returnString addAttribute:(id)kCTFontAttributeName
                         value:(__bridge id)font
                         range:NSMakeRange(0, string.length)];

    CFRelease(font);

    return returnString;
}

+(NSAttributedString*)attributedStringForPost:(NSString*)text andUsername:(NSString*)username
{
    NSMutableAttributedString * returnString = [[NSMutableAttributedString alloc] init];

	if(text == nil)
		text = @"<redacted>";

	[returnString appendAttributedString:[XTTimelineCell normalString:text]];

    return returnString;
}

-(void)awakeFromNib
{
	[super awakeFromNib];

	self.thoughtLabel.dataDetectorTypes = UIDataDetectorTypeLink;
    self.thoughtLabel.delegate = self;

	CALayer * l = self.userPhoto.layer;

    l.masksToBounds = YES;
    l.cornerRadius  = 3;
    l.borderWidth   = 1;
    l.borderColor   = [UIColor darkGrayColor].CGColor;

    UITapGestureRecognizer *_recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(userPhotoTapped:)];

    [self.userPhoto addGestureRecognizer:_recognizer];
    self.userPhoto.userInteractionEnabled = YES;


	UIImage * image = [UIImage imageNamed:@"post-thoughtbubble"];

	image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(23, 20, 20, 8)];

    self.thoughtBubbleBackImageView.image = image;
}

-(void)layoutSubviews
{
    [super layoutSubviews];

	self.thoughtBubbleBackImageView.frame = CGRectMake(45, 5, 263, self.labelHeight+30);
	self.thoughtLabel.frame = CGRectMake(60,
										 27,
										 TEXT_LABEL_WIDTH,
										 self.labelHeight);

	self.quickReplyButton.frame = CGRectMake(285-20, self.labelHeight-10, 40, 40);

}

+(CGFloat)cellHeightForPost:(Post*)post
{
	CGFloat height = [[XTTimelineCell attributedStringForPost:post.text
												  andUsername:post.user.username] heightForWidth:TEXT_LABEL_WIDTH]+2;
	return MAX(25+height+20, 80);
}

-(void)setPost:(Post*)post
{
	_post = post;

	NSAttributedString* attrText = [XTTimelineCell attributedStringForPost:_post.text
															   andUsername:_post.user.username];
	self.thoughtLabel.text = attrText;



	for (XTMention * mention in _post.mentions) {
		[self.thoughtLabel addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"xtendr://showuser/%@", mention.id]]
							  withRange:mention.range];
	}

	for (XTHashTag * hashtag in _post.hashtags) {
		[self.thoughtLabel addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"xtendr://showhashtag/%@", hashtag.name]]
							  withRange:hashtag.range];
	}



	self.labelHeight = [attrText heightForWidth:TEXT_LABEL_WIDTH]+2;

	//self.usernameLabel.text = [NSString stringWithFormat:@"@%@", _post.user.username];
	self.usernameLabel.text = _post.user.username;

	[self.userPhoto loadFromURL:_post.user.avatar.url
			   placeholderImage:[UIImage imageNamed:@"unknown"]
					  fromCache:[XTAppDelegate sharedInstance].userProfilePicCache];



	NSTimeInterval numseconds = abs([post.created_at timeIntervalSinceNow]);
    if(numseconds < 60*60) // 1 hour
    {
        int min = (int)numseconds/60;
        if(numseconds< 60)
        {
            self.timeAgoLabel.text             = NSLocalizedString(@"now", @"");
        }
        else
        {
            self.timeAgoLabel.text             = [NSString stringWithFormat:NSLocalizedString(@"%dm", @""), MAX(1,(int)min)];
        }
    }
    else if(numseconds < 60*60*24) // 1 day
    {
        int hour = (int)numseconds/60/60;
        self.timeAgoLabel.text             = [NSString stringWithFormat:NSLocalizedString(@"%dh", @""), (int)hour];
    }
    else //if(numseconds < 60*60*24*4) // 1 week
    {
        int day = (int)numseconds/60/60/24;
        self.timeAgoLabel.text             = [NSString stringWithFormat:NSLocalizedString(@"%dd", @""), (int)day];
    }


	[self layoutIfNeeded];
}



-(IBAction)userPhotoTapped:(id)sender
{
	DLog(@"USER PHOTO TAPPED!");

	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"xtendr://showuser/%@", _post.user.id]]];
}

-(IBAction)quickReplyTapped:(id)sender
{
	DLog(@"quickReplyTapped!");

	if(self.quickReplyBlock)
	{
		self.quickReplyBlock(_post);
	}
}

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    DLog(@"URL TAPPED: %@", url);

	//TODO: googlechrome://www.google.com

    [[UIApplication sharedApplication] openURL:url];
}

@end
