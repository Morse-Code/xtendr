//
//  ExpandableNavigation.m
//  PathMenuExample
//
//  Created by Tobin Schwaiger-Hastanan on 1/8/12.
//  Copyright (c) 2012 Tobin Schwaiger-Hastanan. All rights reserved.
//

// Highly modified by Tony Million (tonymillion@gmail.com)

#import "ExpandableNavigation.h"

#import "TMMaskView.h"

@interface ExpandableNavigation ()

@property(strong) TMMaskView * mask;

@end

@implementation ExpandableNavigation

@synthesize expandableNavigationDelegate = _expandableNavigationDelegate;

@synthesize mainButton = _mainButton;
@synthesize menuItems = _menuItems;
@synthesize radius = _radius;
@synthesize speed;
@synthesize bounce;
@synthesize bounceSpeed;
@synthesize expanded;
@synthesize transition;

@synthesize mask;
@synthesize onTopOfView;

@synthesize overlay;


- (id)initWithMainButton:(UIButton*)mainButton
				  radius:(CGFloat)radius
				 overlay:(UIView *)theoverlay
{
    if( self = [super init] ) 
    {
        self.mainButton     = mainButton;
        self.overlay        = theoverlay;
        
        self.radius         = radius;
        self.speed          = 0.15;
        self.bounce         = 0.225;
        self.bounceSpeed    = 0.1;
        expanded = NO;
        transition = NO;
        
        if( self.mainButton != nil ) {
            for (UIView* view in self.menuItems) {
                
                view.center = self.mainButton.center;
            }
            
            [self.mainButton addTarget:self
								action:@selector(press:)
					  forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    return self;
}

- (id)init {
    // calling the default init method is not allowed, this will raise an exception if it is called.
    if( self = [super init] ) {
        [self doesNotRecognizeSelector:_cmd];
    }
    return nil;
}

- (void) expand 
{
    transition = YES;
    
    if(_expandableNavigationDelegate && [_expandableNavigationDelegate respondsToSelector:@selector(itemsForExpandableNavigation:)])
    {
        self.menuItems = [_expandableNavigationDelegate itemsForExpandableNavigation:self];
    }
    
    self.mask = [[TMMaskView alloc] init];
    self.mask.delegate  = self;
    self.mask.frame     = self.onTopOfView.frame;
    self.mask.alpha     = 0.0;
    [[self.onTopOfView superview] insertSubview:self.mask 
                                   aboveSubview:self.onTopOfView];
    
    [UIView animateWithDuration:self.speed 
                     animations:^{
                         self.overlay.transform = CGAffineTransformMakeRotation( 135.0 * M_PI/180 );
                         self.mask.alpha = 0.2;
                     }];
     
    
    for (UIView* view in self.menuItems) 
    {
		view.center = self.mainButton.center;
        view.hidden = NO;
        
        int index = [self.menuItems indexOfObject:view];
        CGFloat oneOverCount = self.menuItems.count<=1?1.0:(1.0/(self.menuItems.count-1));
        CGFloat indexOverCount = index * oneOverCount;
        CGFloat rad =(1.0 - indexOverCount) * 90.0 * M_PI/180;
        CGAffineTransform rotation = CGAffineTransformMakeRotation( rad );
		
        CGFloat x = (self.radius + self.bounce * self.radius) * rotation.a;
        CGFloat y = (self.radius + self.bounce * self.radius) * rotation.c;
		
        CGPoint center = CGPointMake( view.center.x + x , view.center.y + y);
        
        [UIView animateWithDuration: self.speed
                              delay: self.speed * indexOverCount
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             view.center = center;
                         } 
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:self.bounceSpeed
                                              animations:^{
                                                  CGFloat x = self.bounce * self.radius * rotation.a;
                                                  CGFloat y = self.bounce * self.radius * rotation.c;
                                                  CGPoint center = CGPointMake( view.center.x - x , view.center.y - y);
                                                  view.center = center;
                                              }];
                             if( view == self.menuItems.lastObject ) {
                                 expanded = YES;
                                 transition = NO;
                             }
                         }];                                                                        
    }
}

- (void) collapse {
    transition = YES;
    
    [UIView animateWithDuration:self.speed 
                     animations:^{
                         self.overlay.transform = CGAffineTransformMakeRotation( 0 );
                         self.mask.alpha = 0.0;
                     } 
                     completion:^(BOOL finished) {
                         [self.mask removeFromSuperview];
                         self.mask = nil;
                     }];
    
    for (UIView* view in self.menuItems) {
        int index = [self.menuItems indexOfObject:view];
        CGFloat oneOverCount = self.menuItems.count<=1?1.0:(1.0/(self.menuItems.count-1));
        CGFloat indexOverCount = index * oneOverCount;
        [UIView animateWithDuration:self.speed
                              delay:(1.0 - indexOverCount) * self.speed
                            options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             view.center = self.mainButton.center;
                         } 
                         completion:^(BOOL finished){                            
                             if( view == self.menuItems.lastObject ) {
                                 expanded = NO;
                                 transition = NO;
                                 
                                 for (UIView* view in self.menuItems) {
                                     view.hidden = YES;
                                 }
                             }
                         }];                                                                         
    }
}

- (IBAction)press:(id)sender {
    if( !self.transition ) {
        if( !self.expanded ) {
            [self expand];
        } else {
            [self collapse];
        }
    }
}

- (void)dealloc {
    self.mainButton = nil;
    self.menuItems = nil;
}

-(void)removeMaskView:(id)sender
{
    [self collapse];
}

@end
