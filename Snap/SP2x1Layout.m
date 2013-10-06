//
//  SP2x1Layout.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SP2x1Layout.h"
#import "SPSegment.h"

@implementation SP2x1Layout {
  CALayer *_horizontalDivider;
  SPSegment *_segment1;
  SPSegment *_segment2;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.totalSegments = 2;

    _horizontalDivider = [CALayer layer];
    [_horizontalDivider setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1].CGColor];
    [self.layer addSublayer:_horizontalDivider];

    _segment1 = [[SPSegment alloc] initWithFrame:CGRectMake(0, 0, (CGRectGetWidth(self.bounds)/2), CGRectGetHeight(self.bounds))];
    [self.segments addObject:_segment1];
    [self addSubview:_segment1];

    _segment2 = [[SPSegment alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_segment1.frame), 0, (CGRectGetWidth(self.bounds)/2), CGRectGetHeight(self.bounds))];
    [self.segments addObject:_segment2];
    [self addSubview:_segment2];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [_horizontalDivider setFrame:CGRectMake(CGRectGetWidth(self.bounds)/2, 0, .5, CGRectGetHeight(self.bounds))];
}

- (void)reset
{
  [super reset];

  [_segment1 setImage:[[UIImage alloc] init]];
  [_segment2 setImage:[[UIImage alloc] init]];
}

@end
