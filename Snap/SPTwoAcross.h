//
//  SPTwoAcross.h
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

@import UIKit;

@interface SPTwoAcross : UIView

@property (nonatomic, strong) NSMutableArray *segments;
@property (nonatomic, strong) NSMutableArray *previews;

@property (nonatomic, strong) UIView *segment1;
@property (nonatomic, strong) UIView *segment2;

@property (nonatomic, strong) UIImageView *preview1;
@property (nonatomic, strong) UIImageView *preview2;

- (UIView *)currentSegment;
- (UIView *)nextSegment;
- (UIView *)previousSegment;
- (BOOL)hasNext;
- (BOOL)hasPrevious;

@end
