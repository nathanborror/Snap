//
//  SPBaseLayout.m
//  Snap
//
//  Created by Nathan Borror on 10/5/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPBaseLayout.h"
#import "SPSegment.h"

@implementation SPBaseLayout

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _segments = [[NSMutableArray alloc] init];
    _index = 0;
    _totalSegments = 0;
  }
  return self;
}

- (SPSegment *)currentSegment
{
  return [_segments objectAtIndex:_index];
}

- (SPSegment *)nextSegment
{
  _index++;
  return [_segments objectAtIndex:_index];
}

- (SPSegment *)previousSegment
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

- (void)reset
{
  _index = 0;
}

@end
