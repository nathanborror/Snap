//
//  SPCollectionCameraViewController.h
//  Snap
//
//  Created by Nathan Borror on 10/13/13.
//  Copyright (c) 2013 Nathan Borror. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import Social;
#import "NBReorderableCollectionViewLayout.h"

@interface SPCollectionCameraViewController : UIViewController <AVCaptureFileOutputRecordingDelegate, UICollectionViewDelegate, NBReorderableCollectionViewDataSource>

@end
