//
//  SPTwoByTwo.h
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

@import UIKit;

@interface SPTwoByTwo : UIView

@property (nonatomic, strong) NSMutableArray *segments;
@property (nonatomic, strong) NSMutableArray *previews;

@property (nonatomic, strong) UIImageView *segment1;
@property (nonatomic, strong) UIImageView *segment2;
@property (nonatomic, strong) UIImageView *segment3;
@property (nonatomic, strong) UIImageView *segment4;

- (UIImageView *)currentSegment;
- (UIImageView *)nextSegment;
- (UIImageView *)previousSegment;
- (BOOL)hasNext;
- (BOOL)hasPrevious;
- (void)finished;

@end
