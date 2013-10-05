//
//  SPTwoAcross.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPTwoAcross.h"

@implementation SPTwoAcross {
  UIView *_hDivider;
  NSMutableArray *_segments;
  NSInteger _index;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _index = 0;
    _segments = [[NSMutableArray alloc] init];
    _previews = [[NSMutableArray alloc] init];

    _hDivider = [[UIView alloc] init];
    [_hDivider setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [self addSubview:_hDivider];

    _segment1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (CGRectGetWidth(self.bounds)/2), CGRectGetHeight(self.bounds))];
    [_segments addObject:_segment1];
    [self addSubview:_segment1];

    _segment2 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_segment1.frame), 0, (CGRectGetWidth(self.bounds)/2), CGRectGetHeight(self.bounds))];
    [_segments addObject:_segment2];
    [self addSubview:_segment2];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  [_hDivider setFrame:CGRectMake(CGRectGetWidth(self.bounds)/2, 0, .5, CGRectGetHeight(self.bounds))];
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
