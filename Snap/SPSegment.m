//
//  SPSegment.m
//  Snap
//
//  Created by Nathan Borror on 10/5/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPSegment.h"

@implementation SPSegment

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    [self setContentMode:UIViewContentModeScaleAspectFill];
  }
  return self;
}

@end
