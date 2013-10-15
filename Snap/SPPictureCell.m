//
//  SPPictureCell.m
//  Snap
//
//  Created by Nathan Borror on 10/13/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPPictureCell.h"

@implementation SPPictureCell {
  UIImageView *_imageView;
}

- (id)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [_imageView setContentMode:UIViewContentModeScaleAspectFill];
    [self addSubview:_imageView];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self setBackgroundColor:[UIColor whiteColor]];
  [_imageView setFrame:self.bounds];
}

- (void)setImage:(UIImage *)image
{
  [_imageView setImage:image];
}

- (void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  if (highlighted) {
    self.alpha = 0.5;
  }
  else {
    self.alpha = 1;
  }
}

- (void)prepareForReuse
{
  [_imageView setImage:[[UIImage alloc] init]];
}

@end
