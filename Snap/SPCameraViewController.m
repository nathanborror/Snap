//
//  SPCameraViewController.m
//  Snap
//
//  Created by Nathan Borror on 10/3/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPCameraViewController.h"
#import "SPTwoByTwo.h"
#import "SPTwoAcross.h"
#import "SPTwoDown.h"
#import "UIImage+Resize.h"

static const CGFloat kMargin = 8;
static const CGFloat kCaptureButtonWidth = 64;
static const CGFloat kUndoButtonWidth = 44;
static const CGFloat kNextButtonWidth = 44;
static const CGFloat kPhotoSize = 1024;

@implementation SPCameraViewController {
  SPTwoByTwo *_viewFinder;
  SPTwoAcross *_viewFinder2Across;
  SPTwoDown *_viewFinder2Down;

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

  _viewFinder = [[SPTwoByTwo alloc] initWithFrame:CGRectMake(0, 80, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds))];
  [_viewFinder setBackgroundColor:[UIColor whiteColor]];
  [self.view addSubview:_viewFinder];

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

  // AVFoundation

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

  [self makePreviewWithView:[_viewFinder currentSegment]];
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

- (void)capture:(UIButton *)button
{
  AVCaptureConnection *videoConnection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
  [(AVCaptureStillImageOutput*)_imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [_photos addObject:image];

    // Replace viewfinder with newly taken photo
    UIImageView *currentSegment = [_viewFinder currentSegment];
    [currentSegment setImage:image];

    if ([_viewFinder hasNext]) {
      UIView *nextSegment = [_viewFinder nextSegment];
      [self makePreviewWithView:nextSegment];
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
    if ([_viewFinder isKindOfClass:[SPTwoByTwo class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake(kPhotoSize, kPhotoSize)];
      [processedPhotos addObject:photo];
    } else if ([_viewFinder isKindOfClass:[SPTwoAcross class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake(kPhotoSize, (kPhotoSize*2))];
      [processedPhotos addObject:photo];
    } else if ([_viewFinder isKindOfClass:[SPTwoDown class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake((kPhotoSize*2), kPhotoSize)];
      [processedPhotos addObject:photo];
    }
  }];

  // Create large image out of grid photos
  UIGraphicsBeginImageContext(size);

  if ([_viewFinder isKindOfClass:[SPTwoByTwo class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:2] drawInRect:CGRectMake(0, kPhotoSize, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:3] drawInRect:CGRectMake(kPhotoSize, kPhotoSize, kPhotoSize, kPhotoSize)];
  } else if ([_viewFinder isKindOfClass:[SPTwoAcross class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, kPhotoSize, (kPhotoSize*2))];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, kPhotoSize, (kPhotoSize*2))];
  } else if ([_viewFinder isKindOfClass:[SPTwoDown class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, (kPhotoSize*2), kPhotoSize)];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, (kPhotoSize*2), kPhotoSize)];
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
    UIImageView *retakeSegment;
    if (_photos.count == 4) {
      retakeSegment = [_viewFinder currentSegment];
    } else {
      retakeSegment = [_viewFinder previousSegment];
    }

    // Remove last photo.
    [_photos removeLastObject];
    NSLog(@"UNDO: %d", _photos.count);

    // Clear the image preview for the segment we're going to retake and
    // move the camera to the segment.
    [[_viewFinder currentSegment] setImage:[[UIImage alloc] init]];
    [self makePreviewWithView:retakeSegment];

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

- (void)makePreviewWithView:(UIView *)view
{
  [_previewLayer removeFromSuperlayer];

  CALayer *rootLayer = [view layer];
  [rootLayer setMasksToBounds:YES];
  [_previewLayer setFrame:CGRectMake(0, 0, CGRectGetWidth(rootLayer.bounds), CGRectGetHeight(rootLayer.bounds))];
  [rootLayer insertSublayer:_previewLayer above:0];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{

}

@end
