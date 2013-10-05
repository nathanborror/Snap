//
//  SPTwoByTwo.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPTwoByTwo.h"

@implementation SPTwoByTwo {
  UIView *_hDivider;
  UIView *_vDivider;
  NSInteger _index;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _index = 0;
    _segments = [[NSMutableArray alloc] init];
    _previews = [[NSMutableArray alloc] init];

    // Dividers
    _hDivider = [[UIView alloc] init];
    [_hDivider setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [self addSubview:_hDivider];

    _vDivider = [[UIView alloc] init];
    [_vDivider setBackgroundColor:[UIColor colorWithWhite:.9 alpha:1]];
    [self addSubview:_vDivider];

    // Segments
    _segment1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [_segment1 setContentMode:UIViewContentModeScaleAspectFill];
    [self.segments addObject:_segment1];
    [self addSubview:_segment1];

    _segment2 = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_segment1.frame), 0, (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [_segment2 setContentMode:UIViewContentModeScaleAspectFill];
    [self.segments addObject:_segment2];
    [self addSubview:_segment2];

    _segment3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_segment1.frame), (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [_segment3 setContentMode:UIViewContentModeScaleAspectFill];
    [self.segments addObject:_segment3];
    [self addSubview:_segment3];

    _segment4 = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_segment3.frame), CGRectGetMaxY(_segment2.frame), (CGRectGetWidth(self.bounds)/2), (CGRectGetHeight(self.bounds)/2))];
    [_segment4 setContentMode:UIViewContentModeScaleAspectFill];
    [self.segments addObject:_segment4];
    [self addSubview:_segment4];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  [_hDivider setFrame:CGRectMake(CGRectGetWidth(self.bounds)/2, 0, .5, CGRectGetHeight(self.bounds))];
  [_vDivider setFrame:CGRectMake(0, CGRectGetHeight(self.bounds)/2, CGRectGetHeight(self.bounds), .5)];
}

- (UIImageView *)currentSegment
{
  return [_segments objectAtIndex:_index];
}

- (UIImageView *)nextSegment
{
  _index++;
  return [_segments objectAtIndex:_index];
}

- (UIImageView *)previousSegment
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
