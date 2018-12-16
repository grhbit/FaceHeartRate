//
//  FacePulseDetector.h
//  faceheartrate
//
//  Created by Gwon Seonggwang on 15/12/2018.
//  Copyright © 2018. All rights reserved.
//

#import <React/RCTView.h>
#import <AVFoundation/AVFoundation.h>
#import <React/RCTBridge.h>
#import <React/RCTBridgeModule.h>
#import <UIKit/UIKit.h>

@class RCTEventDispatcher;

@interface FacePulseDetector : RCTView<AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic, strong) dispatch_queue_t sessionQueue;
@property(nonatomic, strong) dispatch_queue_t sampleBufferCallbackQueue;
@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureDeviceInput *videoCaptureDeviceInput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property(nonatomic, strong) UIImageView *extView;

- (id)initWithBridge:(RCTBridge *)bridge;
- (void)onFacesDetected:(NSNumber *)trackingID lt:(CGPoint)lt lb:(CGPoint)lb rt:(CGPoint)rt rb:(CGPoint)rb;
- (void)onHeartRate:(NSNumber *)trackingID withMeanBpm:(NSNumber *)meanBpm withMaxBpm:(NSNumber *)maxBpm withMinBpm:(NSNumber *)minBpm;

@end
