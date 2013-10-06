//
//  SP2x2Layout.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SP2x2Layout.h"
#import "SPSegment.h"

@implementation SP2x2Layout {
  CALayer *_horizontalDivider;
  CALayer *_verticalDivider;
  SPSegment *_segment1;
  SPSegment *_segment2;
  SPSegment *_segment3;
  SPSegment *_segment4;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    self.totalSegments = 4;

    _horizontalDivider = [CALayer layer];
    [_horizontalDivider setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1].CGColor];
    [self.layer addSublayer:_horizontalDivider];

    _verticalDivider = [CALayer layer];
    [_verticalDivider setBackgroundColor:[UIColor colorWithWhite:.8 alpha:1].CGColor];
    [self.layer addSublayer:_verticalDivider];

    // Segments
    _segment1 = [[SPSegment alloc] initWithFrame:CGRectMake(0, 0, (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [self.segments addObject:_segment1];
    [self addSubview:_segment1];

    _segment2 = [[SPSegment alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_segment1.frame), 0, (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [self.segments addObject:_segment2];
    [self addSubview:_segment2];

    _segment3 = [[SPSegment alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_segment1.frame), (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [self.segments addObject:_segment3];
    [self addSubview:_segment3];

    _segment4 = [[SPSegment alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_segment3.frame), CGRectGetMaxY(_segment2.frame), (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [self.segments addObject:_segment4];
    [self addSubview:_segment4];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  [_horizontalDivider setFrame:CGRectMake(CGRectGetWidth(self.bounds)/2, 0, .5, CGRectGetHeight(self.bounds))];
  [_verticalDivider setFrame:CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetHeight(self.bounds), .5)];
}

- (void)reset
{
  [super reset];

  [_segment1 setImage:[[UIImage alloc] init]];
  [_segment2 setImage:[[UIImage alloc] init]];
  [_segment3 setImage:[[UIImage alloc] init]];
  [_segment4 setImage:[[UIImage alloc] init]];
}

@end
