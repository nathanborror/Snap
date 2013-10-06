//
//  SP1x2Layout.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SP1x2Layout.h"
#import "SPSegment.h"

@implementation SP1x2Layout {
  CALayer *_verticalDivider;
  SPSegment *_segment1;
  SPSegment *_segment2;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.totalSegments = 2;

    _verticalDivider = [CALayer layer];
    [_verticalDivider setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1].CGColor];
    [self.layer addSublayer:_verticalDivider];

    _segment1 = [[SPSegment alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), (CGRectGetHeight(self.bounds)/2))];
    [self.segments addObject:_segment1];
    [self addSubview:_segment1];

    _segment2 = [[SPSegment alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_segment1.frame), CGRectGetWidth(self.bounds), (CGRectGetHeight(self.bounds)/2))];
    [self.segments addObject:_segment2];
    [self addSubview:_segment2];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [_verticalDivider setFrame:CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), .5)];
}

- (void)reset
{
  [super reset];

  [_segment1 setImage:[[UIImage alloc] init]];
  [_segment2 setImage:[[UIImage alloc] init]];
}

@end
