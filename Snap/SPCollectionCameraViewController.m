//
//  SPCollectionCameraViewController.m
//  Snap
//
//  Created by Nathan Borror on 10/13/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

#import "SPCollectionCameraViewController.h"
#import "NBReorderableCollectionViewLayout.h"
#import "SPPictureCell.h"
#import "UIImage+Resize.h"

static const CGFloat kCameraWidth = 159.5;
static const CGFloat kCameraHeight = kCameraWidth;
static const CGFloat kCaptureButtonWidth = 64;
static const CGFloat kUndoButtonWidth = 44;
static const CGFloat kNextButtonWidth = 44;
static const CGFloat kPhotoSize = 1024;

@implementation SPCollectionCameraViewController {
  UICollectionView *_collectionView;
  UIButton *_captureButton;
  UIButton *_undoButton;
  SPPictureCell *_currentCell;
  UIImage *_result;
  UIButton *_layout1Button;
  UIButton *_layout2Button;
  UIButton *_layout3Button;
  UIView *_layoutIndicator;

  NSMutableArray *_photos;
  NSInteger _totalCells;

  AVCaptureSession *_captureSession;
  AVCaptureStillImageOutput *_imageOutput;
  AVCaptureVideoPreviewLayer *_previewLayer;
  AVPlayer *_player;
  AVPlayer *_playerLayer;
  AVCaptureDevice *_device;
  AVCaptureDeviceInput *_deviceInput;
}

- (id)init
{
  if (self = [super init]) {
    [self.view setBackgroundColor:[UIColor blackColor]];
    _photos = [[NSMutableArray alloc] init];
    _totalCells = 4;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  NBReorderableCollectionViewLayout *layout = [[NBReorderableCollectionViewLayout alloc] init];
  [layout setMinimumLineSpacing:1];
  [layout setMinimumInteritemSpacing:1];
  [layout setItemSize:CGSizeMake(kCameraWidth, kCameraHeight)];

  _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 60, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)) collectionViewLayout:layout];
  [_collectionView setClipsToBounds:NO];
  [_collectionView registerClass:[SPPictureCell class] forCellWithReuseIdentifier:@"SPPictureCell"];
  [_collectionView setDelegate:self];
  [_collectionView setDataSource:self];
  [_collectionView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
  [self.view addSubview:_collectionView];

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

  UIButton *flipCamera = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-52, 8, 44, 44)];
  [flipCamera setBackgroundImage:[UIImage imageNamed:@"FlipCameraIcon"] forState:UIControlStateNormal];
  [flipCamera addTarget:self action:@selector(flipCamera:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:flipCamera];

  // Carousel

  UIView *carousel = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_collectionView.frame)+20, CGRectGetWidth(self.view.bounds), 44)];
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

    _device = [self backCamera];

    NSError *deviceError;
    _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&deviceError];
    [_captureSession addInput:_deviceInput];

    _imageOutput = [[AVCaptureStillImageOutput alloc] init];

    if (deviceError) {
      NSLog(@"Error occurred while attempting to capture %@", deviceError.localizedDescription);
    }

    [_captureSession addOutput:_imageOutput];

    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_previewLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  } else {
    _previewLayer = [CALayer layer];
    [_previewLayer setBackgroundColor:[UIColor redColor].CGColor];
  }
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

- (AVCaptureDevice *)frontCamera
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *device in devices) {
    if ([device position] == AVCaptureDevicePositionFront) {
      return device;
    }
  }
  return nil;
}

- (AVCaptureDevice *)backCamera
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  for (AVCaptureDevice *device in devices) {
    if ([device position] == AVCaptureDevicePositionBack) {
      return device;
    }
  }
  return nil;
}

- (void)flipCamera:(UIButton *)button
{
  if (_device.position == AVCaptureDevicePositionBack) {
    _device = [self frontCamera];
  } else {
    _device = [self backCamera];
  }

  // Remove old input
  [_captureSession removeInput:_deviceInput];

  // Add new input
  NSError *deviceError;
  _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&deviceError];
  [_captureSession addInput:_deviceInput];
}

- (void)capture:(UIButton *)button
{
  AVCaptureConnection *videoConnection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
  [(AVCaptureStillImageOutput*)_imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
    NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    [_photos addObject:image];

    // Replace viewfinder with newly taken photo
    [_currentCell setImage:image];

    SPPictureCell *nextCell = [self nextCell];
    [self makePreviewWithCell:nextCell];
    _currentCell = nextCell;

    [self reset];
  }];
}

- (void)undo:(UIButton *)button
{
  SPPictureCell *previousCell = [self previousCell];
  if (previousCell) {
    // Remove last photo.
    [_photos removeLastObject];

    [self makePreviewWithCell:previousCell];
    [previousCell setImage:[[UIImage alloc] init]];
    _currentCell = previousCell;

    [self reset];
  }
}

- (void)share:(UIButton *)button
{
  CGSize size = CGSizeMake(kPhotoSize*2, kPhotoSize*2);

  NSMutableArray *processedPhotos = [[NSMutableArray alloc] init];
  [_photos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if (_totalCells == 4) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake(kPhotoSize, kPhotoSize)];
      [processedPhotos addObject:photo];
    } else if (_totalCells == 2) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake(kPhotoSize, (kPhotoSize*2))];
      [processedPhotos addObject:photo];
    }/* else if ([_viewFinder isKindOfClass:[SP1x2Layout class]]) {
      UIImage *photo = [(UIImage *)obj imageByScalingAndCroppingForSize:CGSizeMake((kPhotoSize*2), kPhotoSize)];
      [processedPhotos addObject:photo];
    }*/
  }];

  // Create large image out of grid photos
  UIGraphicsBeginImageContext(size);

  if (_totalCells == 4) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:2] drawInRect:CGRectMake(0, kPhotoSize, kPhotoSize, kPhotoSize)];
    [[processedPhotos objectAtIndex:3] drawInRect:CGRectMake(kPhotoSize, kPhotoSize, kPhotoSize, kPhotoSize)];
  } else if (_totalCells == 2) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, kPhotoSize, (kPhotoSize*2))];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(kPhotoSize, 0, kPhotoSize, (kPhotoSize*2))];
  }/* else if ([_viewFinder isKindOfClass:[SP1x2Layout class]]) {
    [[processedPhotos objectAtIndex:0] drawInRect:CGRectMake(0, 0, (kPhotoSize*2), kPhotoSize)];
    [[processedPhotos objectAtIndex:1] drawInRect:CGRectMake(0, kPhotoSize, (kPhotoSize*2), kPhotoSize)];
  }*/

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

- (void)makePreviewWithCell:(SPPictureCell *)cell
{
  [_previewLayer removeFromSuperlayer];

  CALayer *rootLayer = [cell layer];
  [rootLayer setMasksToBounds:YES];
  [_previewLayer setFrame:CGRectMake(0, 0, CGRectGetWidth(rootLayer.bounds), CGRectGetHeight(rootLayer.bounds))];
  [rootLayer insertSublayer:_previewLayer above:0];
}

- (SPPictureCell *)nextCell
{
  NSIndexPath *indexPath = [_collectionView indexPathForCell:_currentCell];
  if (indexPath.row+1 < _totalCells) {
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:indexPath.row+1 inSection:indexPath.section];
    return (SPPictureCell *)[_collectionView cellForItemAtIndexPath:nextIndexPath];
  }
  return nil;
}

- (SPPictureCell *)previousCell
{
  NSIndexPath *indexPath;
  if (!_currentCell) {
    return (SPPictureCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:(_photos.count-1) inSection:0]];
  } else {
    indexPath = [_collectionView indexPathForCell:_currentCell];
    if (indexPath.row-1 >= 0) {
      NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:indexPath.row-1 inSection:indexPath.section];
      return (SPPictureCell *)[_collectionView cellForItemAtIndexPath:nextIndexPath];
    }
  }
  return nil;
}

- (void)verticalGrid:(UIButton *)button
{
  [_layout1Button setAlpha:1];
  [_layout2Button setAlpha:.4];
  [_layout3Button setAlpha:.4];

  [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveLinear animations:^{
    [_layoutIndicator setCenter:CGPointMake(_layout1Button.center.x, _layoutIndicator.center.y)];
  } completion:^(BOOL finished) {
    _totalCells = 2;
    [_photos removeAllObjects];

    [(NBReorderableCollectionViewLayout *)_collectionView.collectionViewLayout setItemSize:CGSizeMake(kCameraWidth, 320)];
    [_collectionView reloadData];

    [self reset];
  }];
}

- (void)fullGrid:(UIButton *)button
{
  [_layout1Button setAlpha:.4];
  [_layout2Button setAlpha:1];
  [_layout3Button setAlpha:.4];

  [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveLinear animations:^{
    [_layoutIndicator setCenter:CGPointMake(_layout2Button.center.x, _layoutIndicator.center.y)];
  } completion:^(BOOL finished) {
    _totalCells = 4;
    [_photos removeAllObjects];

    [(NBReorderableCollectionViewLayout *)_collectionView.collectionViewLayout setItemSize:CGSizeMake(kCameraWidth, kCameraHeight)];
    [_collectionView reloadData];

    [self reset];
  }];
}

- (void)horizontalGrid:(UIButton *)button
{
  [_layout1Button setAlpha:.4];
  [_layout2Button setAlpha:.4];
  [_layout3Button setAlpha:1];

  [UIView animateWithDuration:.5 delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.2 options:UIViewAnimationOptionCurveLinear animations:^{
    [_layoutIndicator setCenter:CGPointMake(_layout3Button.center.x, _layoutIndicator.center.y)];
  } completion:^(BOOL finished) {
    _totalCells = 2;
    [_photos removeAllObjects];

    [(NBReorderableCollectionViewLayout *)_collectionView.collectionViewLayout setItemSize:CGSizeMake(320, kCameraHeight)];
    [_collectionView reloadData];

    [self reset];
  }];
}

- (void)reset
{
  // Only show undo button if there are photos.
  if ([_photos count] > 0) {
    [_undoButton setHidden:NO];
  } else {
    [_undoButton setHidden:YES];
  }

  if (_photos.count == _totalCells) {
    // Repurpose the capture button to be a share button.
    [_captureButton setBackgroundImage:[UIImage imageNamed:@"NextButtonDefault"] forState:UIControlStateNormal];
    [_captureButton setBackgroundImage:[UIImage imageNamed:@"NextButtonPressed"] forState:UIControlStateHighlighted];
    [_captureButton removeTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];
    [_captureButton addTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
  } else {
    // Reset capture button so it's not in a sharing state.
    [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonDefault"] forState:UIControlStateNormal];
    [_captureButton setBackgroundImage:[UIImage imageNamed:@"CameraButtonPressed"] forState:UIControlStateHighlighted];
    [_captureButton removeTarget:self action:@selector(share:) forControlEvents:UIControlEventTouchUpInside];
    [_captureButton addTarget:self action:@selector(capture:) forControlEvents:UIControlEventTouchUpInside];
  }
}

#pragma mark - NBReorderableCollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return _totalCells;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  SPPictureCell *cell = (SPPictureCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"SPPictureCell" forIndexPath:indexPath];
  if (indexPath.row == [_photos count]) {
    [self makePreviewWithCell:cell];
    _currentCell = cell;
  }

  if (_photos.count != 0 && indexPath.row <= _photos.count) {
    [cell setImage:[_photos objectAtIndex:indexPath.row]];
  }

  return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
  if (_photos.count > 0 && _photos.count >= fromIndexPath.row) {
    UIImage *image = [_photos objectAtIndex:fromIndexPath.row];
    [_photos removeObjectAtIndex:fromIndexPath.row];
    [_photos insertObject:image atIndex:toIndexPath.row];
  }
}

@end
