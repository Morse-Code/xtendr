//
//  ExpandableNavigation.h
//  PathMenuExample
//
//  Created by Tobin Schwaiger-Hastanan on 1/8/12.
//  Copyright (c) 2012 Tobin Schwaiger-Hastanan. All rights reserved.
//

// Highly modified by Tony Million (tonymillion@gmail.com)

#import <Foundation/Foundation.h>

@class ExpandableNavigation;

@protocol ExpandableNavigationDelegate <NSObject>

-(NSArray*)itemsForExpandableNavigation:(ExpandableNavigation*)nav;
-(void)expandableNavigationDidCollapse:(ExpandableNavigation*)nav;

@end

@interface ExpandableNavigation : NSObject 
{
    UIButton* _mainButton;
    NSArray* _menuItems;
    CGFloat _radius;
    CGFloat speed;
    CGFloat bounce;
    CGFloat bounceSpeed;    
    BOOL expanded;
    BOOL transition;
}

@property(weak) id<ExpandableNavigationDelegate> expandableNavigationDelegate;

@property(weak) UIView * onTopOfView;

@property(strong) UIView * overlay;

@property (retain) UIButton* mainButton;
@property (retain) NSArray* menuItems;
@property CGFloat radius;
@property CGFloat speed;
@property CGFloat bounce;
@property CGFloat bounceSpeed;
@property (readonly) BOOL expanded;
@property (readonly) BOOL transition;

- (id)initWithMainButton:(UIButton*)mainButton
				  radius:(CGFloat)radius
				 overlay:(UIView *)theoverlay;
- (id)init;

- (void) expand;
- (void) collapse;

@end
