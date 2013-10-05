//
//  UIImage+Resize.h
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize;

@end
