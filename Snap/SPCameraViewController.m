//
//  SPCameraViewController.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPCameraViewController.h"
#import "SPBaseLayout.h"
#import "SP2x1Layout.h"
#import "SP2x2Layout.h"
#import "SP1x2Layout.h"
#import "UIImage+Resize.h"
#import "SPSegment.h"

static const CGFloat kMargin = 8;
static const CGFloat kCaptureButtonWidth = 64;
static const CGFloat kUndoButtonWidth = 44;
static const CGFloat kNextButtonWidth = 44;
static const CGFloat kPhotoSize = 1024;

@implementation SPCameraViewController {
  SP2x1Layout *_viewFinder2x1;
  SP2x2Layout *_viewFinder2x2;
  SP1x2Layout *_viewFinder1x2;
  SPBaseLayout *_viewFinder;

  UIButton *_captureButton;
  UIButton *_undoButton;

  AVCaptureSession *_captureSession;
  AVCaptureStillImageOutput *_imageOutput;
  AVCaptureVideoPreviewLayer *_previewLayer;
  AVPlayer *_player;
  AVPlayer *_playerLayer;

  BOOL _isSaved;
  UIImage *_result;
  NSInteger _gridSize;
  NSMutableArray *_photos;

  UIButton *_layout1Button;
  UIButton *_layout2Button;
  UIButton *_layout3Button;
  UIView *_layoutIndicator;
}

- (id)init
{
  if (self = [super init]) {
    [self.view setBackgroundColor:[UIColor blackColor]];
    _isSaved = NO;
    _gridSize = 4;
    _photos = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _viewFinder2x1 = [[SP2x1Layout alloc] initWithFrame:CGRectMake(-(CGRectGetWidth(self.view.bounds)), 60, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))];
  [_viewFinder2x1 setBackgroundColor:[UIColor whiteColor]];
  [self.view addSubview:_viewFinder2x1];

  _viewFinder2x2 = [[SP2x2Layout alloc] initWithFrame:CGRectMake(0, 60, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))];
  [_viewFinder2x2 setBackgroundColor:[UIColor whiteColor]];
  [self.view addSubview:_viewFinder2x2];

  _viewFinder1x2 = [[SP1x2Layout alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds), 60, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))];
  [_viewFinder1x2 setBackgroundColor:[UIColor whiteColor]];
  [self.view addSubview:_viewFinder1x2];

  _viewFinder = _viewFinder2x2;

  _captureButton = [[UIButton alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.bounds)/2)-(kCaptureButtonWidth/2), CGRectGetHeight(self.view.bounds)-(kCaptureButtonWidth+32), kCaptureButtonWidth, kCaptureButtonWidth)];
  [_captureButton addTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];
  [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonDefault"] forState:UIControlStateNormal];
  [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonPressed"] forState:UIControlStateHighlighted];
  [self.view addSubview:_captureButton];

  _undoButton = [[UIButton alloc] initWithFrame:CGRectMake(32, CGRectGetMinY(_captureButton.frame)+10, 64, 39)];
  [_undoButton addTarget:self action:@selector(undo:) forControlEvents:UIControlEventTouchUpInside];
  [_undoButton setBackgroundImage:[UIImage imageNamed:@"BackspaceDefault"] forState:UIControlStateNormal];
  [_undoButton setHidden:YES];
  [self.view addSubview:_undoButton];

  UIView *carousel = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_viewFinder.frame)+20, CGRectGetWidth(self.view.bounds), 44)];
  [self.view addSubview:carousel];

  _layout1Button = [[UIButton alloc] initWithFrame:CGRectMake(44, 0, 44, 44)];
  [_layout1Button addTarget:self action:@selector(verticalGrid:) forControlEvents:UIControlEventTouchUpInside];
  [_layout1Button setBackgroundImage:[UIImage imageNamed:@"2GridVertical"] forState:UIControlStateNormal];
  [_layout1Button setAlpha:.4];
  [carousel addSubview:_layout1Button];

  _layout2Button = [[UIButton alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.bounds)/2)-(44/2), 0, 44, 44)];
  [_layout2Button addTarget:self action:@selector(fullGrid:) forControlEvents:UIControlEventTouchUpInside];
  [_layout2Button setBackgroundImage:[UIImage imageNamed:@"4Grid"] forState:UIControlStateNormal];
  [carousel addSubview:_layout2Button];

  _layout3Button = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds)-88, 0, 44, 44)];
  [_layout3Button addTarget:self action:@selector(horizontalGrid:) forControlEvents:UIControlEventTouchUpInside];
  [_layout3Button setBackgroundImage:[UIImage imageNamed:@"2GridHorizontal"] forState:UIControlStateNormal];
  [_layout3Button setAlpha:.4];
  [carousel addSubview:_layout3Button];

  _layoutIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 6)];
  [_layoutIndicator setBackgroundColor:[UIColor colorWithRed:1 green:.79 blue:.18 alpha:1]];
  [_layoutIndicator.layer setCornerRadius:3];
  [_layoutIndicator setCenter:CGPointMake(_layout2Button.center.x, 48)];
  [carousel addSubview:_layoutIndicator];

  // AVFoundation

  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    NSError *deviceError;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&deviceError];
    [_captureSession addInput:deviceInput];

    _imageOutput = [[AVCaptureStillImageOutput alloc] init];

    if (deviceError) {
      NSLog(@"Error occurred while attempting to capture %@", deviceError.localizedDescription);
    }

    [_captureSession addOutput:_imageOutput];

    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_previewLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  }

  [self makePreviewWithSegment:[_viewFinder currentSegment]];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [_captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [_captureSession stopRunning];
}

- (void)verticalGrid:(UIButton *)button
{
  [_layout1Button setAlpha:1];
  [_layout2Button setAlpha:.4];
  [_layout3Button setAlpha:.4];

  _viewFinder = _viewFinder2x1;
  [self reset];

  [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveLinear animations:^{
    [_layoutIndicator setCenter:CGPointMake(_layout1Button.center.x, _layoutIndicator.center.y)];

    [_viewFinder2x1 setFrame:CGRectOffset(_viewFinder2x1.bounds, 0, CGRectGetMinY(_viewFinder2x1.frame))];
    [_viewFinder2x2 setFrame:CGRectOffset(_viewFinder2x2.bounds, CGRectGetWidth(_viewFinder2x2.bounds), CGRectGetMinY(_viewFinder2x2.frame))];
    [_viewFinder1x2 setFrame:CGRectOffset(_viewFinder1x2.bounds, CGRectGetWidth(_viewFinder1x2.bounds)*2, CGRectGetMinY(_viewFinder1x2.frame))];
  } completion:^(BOOL finished) {
    [self makePreviewWithSegment:[_viewFinder currentSegment]];
  }];
}

- (void)fullGrid:(UIButton *)button
{
  [_layout1Button setAlpha:.4];
  [_layout2Button setAlpha:1];
  [_layout3Button setAlpha:.4];

  _viewFinder = _viewFinder2x2;
  [self reset];

  [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveLinear animations:^{
    [_layoutIndicator setCenter:CGPointMake(_layout2Button.center.x, _layoutIndicator.center.y)];

    [_viewFinder2x1 setFrame:CGRectOffset(_viewFinder2x1.bounds, -(CGRectGetWidth(_viewFinder2x1.bounds)), CGRectGetMinY(_viewFinder2x1.frame))];
    [_viewFinder2x2 setFrame:CGRectOffset(_viewFinder2x2.bounds, 0, CGRectGetMinY(_viewFinder2x2.frame))];
    [_viewFinder1x2 setFrame:CGRectOffset(_viewFinder1x2.bounds, CGRectGetWidth(_viewFinder1x2.bounds), CGRectGetMinY(_viewFinder1x2.frame))];
  } completion:^(BOOL finished) {
    [self makePreviewWithSegment:[_viewFinder currentSegment]];
  }];
}

- (void)horizontalGrid:(UIButton *)button
{
  [_layout1Button setAlpha:.4];
  [_layout2Button setAlpha:.4];
  [_layout3Button setAlpha:1];

  _viewFinder = _viewFinder1x2;
  [self reset];

  [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveLinear animations:^{
    [_layoutIndicator setCenter:CGPointMake(_layout3Button.center.x, _layoutIndicator.center.y)];

    [_viewFinder2x1 setFrame:CGRectOffset(_viewFinder2x1.bounds, -(CGRectGetWidth(_viewFinder2x1.bounds)*2), CGRectGetMinY(_viewFinder2x1.frame))];
    [_viewFinder2x2 setFrame:CGRectOffset(_viewFinder2x2.bounds, -(CGRectGetWidth(_viewFinder2x2.bounds)), CGRectGetMinY(_viewFinder2x2.frame))];
    [_viewFinder1x2 setFrame:CGRectOffset(_viewFinder1x2.bounds, 0, CGRectGetMinY(_viewFinder1x2.frame))];
  } completion:^(BOOL finished) {
    [self makePreviewWithSegment:[_viewFinder currentSegment]];
  }];
}

- (void)capture:(UIButton *)button
{
  AVCaptureConnection *videoConnection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
  [(AVCaptureStillImageOutput*)_imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [_photos addObject:image];

    // Replace viewfinder with newly taken photo
    SPSegment *currentSegment = [_viewFinder currentSegment];
    [currentSegment setImage:image];

    if ([_viewFinder hasNext]) {
      SPSegment *nextSegment = [_viewFinder nextSegment];
      [self makePreviewWithSegment:nextSegment];
    } else {
      // Repurpose the capture button to be a share button.
      [_captureButton setBackgroundImage:[UIImage imageNamed:@"NextButtonDefault"] forState:UIControlStateNormal];
      [_captureButton setBackgroundImage:[UIImage imageNamed:@"NextButtonPressed"] forState:UIControlStateHighlighted];
      [_captureButton removeTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];
      [_captureButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];

      // Since we've taken the last photo, remove the camera preview
      // from the last segment so we see the last photo.
      [_previewLayer removeFromSuperlayer];
    }

    // Only show undo button if there are photos.
    if ([_photos count] > 0) {
      [_undoButton setHidden:NO];
    } else {
      [_undoButton setHidden:YES];
    }
  }];
}

- (void)share:(UIButton *)button
{
  CGSize size = CGSizeMake(kPhotoSize*2, kPhotoSize*2);

  NSMutableArray *processedPhotos = [[NSMutableArray alloc] init];
  [_photos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([_viewFinder isKindOfClass:[SP2x2Layout class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake(kPhotoSize, kPhotoSize)];
      [processedPhotos addObject:photo];
    } else if ([_viewFinder isKindOfClass:[SP2x1Layout class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake(kPhotoSize, (kPhotoSize*2))];
      [processedPhotos addObject:photo];
    } else if ([_viewFinder isKindOfClass:[SP1x2Layout class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake((kPhotoSize*2), kPhotoSize)];
      [processedPhotos addObject:photo];
    }
  }];

  // Create large image out of grid photos
  UIGraphicsBeginImageContext(size);

  if ([_viewFinder isKindOfClass:[SP2x2Layout class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:2] drawInRect:CGRectMake(0, kPhotoSize, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:3] drawInRect:CGRectMake(kPhotoSize, kPhotoSize, kPhotoSize, kPhotoSize)];
  } else if ([_viewFinder isKindOfClass:[SP2x1Layout class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, kPhotoSize, (kPhotoSize*2))];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, kPhotoSize, (kPhotoSize*2))];
  } else if ([_viewFinder isKindOfClass:[SP1x2Layout class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, (kPhotoSize*2), kPhotoSize)];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(0, kPhotoSize, (kPhotoSize*2), kPhotoSize)];
  }

  _result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // Save image to camera roll
  UIImageWriteToSavedPhotosAlbum(_result, nil, nil, nil);

  if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
    SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [composer addImage:_result];
    [self presentViewController:composer animated:YES completion:nil];
  }
}

- (void)undo:(UIButton *)button
{
  if ([_viewFinder hasPrevious]) {
    SPSegment *retakeSegment;
    if (_photos.count == _viewFinder.totalSegments) {
      retakeSegment = [_viewFinder currentSegment];
    } else {
      retakeSegment = [_viewFinder previousSegment];
    }

    // Remove last photo.
    [_photos removeLastObject];

    // Clear the image preview for the segment we're going to retake and
    // move the camera to the segment.
    [[_viewFinder currentSegment] setImage:[[UIImage alloc] init]];
    [self makePreviewWithSegment:retakeSegment];

    // Reset capture button so it's not in a sharing state.
    [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonDefault"] forState:UIControlStateNormal];
    [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonPressed"] forState:UIControlStateHighlighted];
    [_captureButton removeTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    [_captureButton addTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];

    // Hide undo button if all photos have been cleared.
    if (_photos.count == 0) {
      [_undoButton setHidden:YES];
    }
  }
}

- (void)makePreviewWithSegment:(SPSegment *)segment
{
  [_previewLayer removeFromSuperlayer];

  CALayer *rootLayer = [segment layer];
  [rootLayer setMasksToBounds:YES];
  [_previewLayer setFrame:CGRectMake(0, 0, CGRectGetWidth(rootLayer.bounds), CGRectGetHeight(rootLayer.bounds))];
  [rootLayer insertSublayer:_previewLayer above:0];
}

- (void)reset
{
  [_viewFinder reset];
  [_photos removeAllObjects];

  // Reset capture button so it's not in a sharing state.
  [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonDefault"] forState:UIControlStateNormal];
  [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonPressed"] forState:UIControlStateHighlighted];
  [_captureButton removeTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
  [_captureButton addTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];

  // Hide undo button if all photos have been cleared.
  [_undoButton setHidden:YES];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{

}

@end
