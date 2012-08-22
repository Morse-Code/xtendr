//
//  ZZMaskView.m
//  //
//
//  Created by Tony Million on 15/12/2011.
//  Copyright (c) 2011 OmniTyke. All rights reserved.
//

#import "TMMaskView.h"

@implementation TMMaskView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(removeMaskView:)])
        [self.delegate performSelector:@selector(removeMaskView:) 
                            withObject:self];
}

@end
