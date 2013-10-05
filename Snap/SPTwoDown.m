//
//  SPTwoDown.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPTwoDown.h"

@implementation SPTwoDown {
  CALayer *_verticalDivider;
  NSMutableArray *_segments;
  NSInteger _index;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _index = 0;
    _segments = [[NSMutableArray alloc] init];
    _previews = [[NSMutableArray alloc] init];

    _verticalDivider = [CALayer layer];
    [_verticalDivider setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1].CGColor];
    [self.layer addSublayer:_verticalDivider];

    _segment1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), (CGRectGetHeight(self.bounds)/2))];
    [_segments addObject:_segment1];
    [self addSubview:_segment1];

    _segment2 = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.bounds), CGRectGetWidth(self.bounds), (CGRectGetHeight(self.bounds)/2))];
    [_segments addObject:_segment2];
    [self addSubview:_segment2];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [_verticalDivider setFrame:CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetWidth(self.bounds), .5)];
}

- (UIView *)currentSegment
{
  return [_segments objectAtIndex:_index];
}

- (UIView *)nextSegment
{
  _index++;
  return [_segments objectAtIndex:_index];
}

- (UIView *)previousSegment
{
  _index--;
  return [_segments objectAtIndex:_index];
}

- (BOOL)hasNext
{
  return _index < (_segments.count-1);
}

- (BOOL)hasPrevious
{
  return _index > 0;
}

@end
