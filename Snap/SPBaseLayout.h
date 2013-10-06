//
//  SPBaseLayout.h
//  Snap
//
//  Created by Nathan Borror on 10/5/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPSegment;

@interface SPBaseLayout : UIView

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSMutableArray *segments;
@property (nonatomic, assign) NSInteger totalSegments;

- (SPSegment *)currentSegment;
- (SPSegment *)nextSegment;
- (SPSegment *)previousSegment;
- (BOOL)hasNext;
- (BOOL)hasPrevious;
- (void)reset;

@end
