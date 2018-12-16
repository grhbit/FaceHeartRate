//
//  FacePulseDetector.m
//  faceheartrate
//
//  Created by Gwon Seonggwang on 15/12/2018.
//  Copyright © 2018. All rights reserved.
//

#import <React/UIView+React.h>
#import <opencv2/core/core.hpp>
#import <opencv2/opencv.hpp>
#import <Firebase/Firebase.h>
#import <map>
#import <set>
#import <iostream>

#import "FacePulseDetector.h"
#import "ImageUtils.h"
#import "RPPG.hpp"

@interface FacePulseDetector ()

@property (nonatomic, weak) RCTBridge *bridge;
@property (nonatomic, strong) FIRVision *vision;
@property (nonatomic, strong) FIRVisionFaceDetector *faceDetector;
@property (nonatomic, copy) RCTDirectEventBlock onFacesDetected;
@property (nonatomic, copy) RCTDirectEventBlock onHeartRate;

@end

@implementation FacePulseDetector {
    std::map<long, RPPG> rppgMap;
}

- (id)initWithBridge:(RCTBridge *)bridge
{
    if ((self = [super init])) {
        self.bridge = bridge;
        self.session = [AVCaptureSession new];
        self.sessionQueue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL);
        
        FIRVisionFaceDetectorOptions *options = [[FIRVisionFaceDetectorOptions alloc] init];
        options.performanceMode = FIRVisionFaceDetectorPerformanceModeAccurate;
        options.contourMode = FIRVisionFaceDetectorContourModeAll;
        options.trackingEnabled = TRUE;
        
        self.vision = [FIRVision vision];
        self.faceDetector = [self.vision faceDetectorWithOptions:options];

        self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.previewLayer.needsDisplayOnBoundsChange = YES;
        [self setUpCaptureSessionOutput];
        [self setUpCaptureSessionInput];
        [self startSession];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.previewLayer.frame = self.bounds;
    [self setBackgroundColor:[UIColor blackColor]];
    [self.layer insertSublayer:self.previewLayer atIndex:0];
}

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
    UIView *_view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
    self.extView = [[UIImageView alloc] init];
    self.extView.frame = _view.bounds;
    
    [_view addSubview:self.extView];
    [self insertSubview:_view atIndex:atIndex + 2];

    [self insertSubview:view atIndex:atIndex + 1];
    [super insertReactSubview:view atIndex:atIndex];

    return;
}

- (void)removeReactSubview:(UIView *)subview
{
    [subview removeFromSuperview];
    [super removeReactSubview:subview];
}

- (void)removeFromSuperview
{
    [super removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [self stopSession];
}

- (void)startSession
{
    dispatch_async(self.sessionQueue, ^{
        [self.session startRunning];
    });
}

- (void)stopSession
{
    dispatch_async(self.sessionQueue, ^{
        [self.previewLayer removeFromSuperlayer];
        [self.session commitConfiguration];
        [self.session stopRunning];
        for (AVCaptureInput *input in self.session.inputs) {
            [self.session removeInput:input];
        }
        
        for (AVCaptureOutput *output in self.session.outputs) {
            [self.session removeOutput:output];
        }
    });
}

- (void)setUpCaptureSessionInput
{
    __block UIInterfaceOrientation interfaceOrientation;
    
    void (^statusBlock)() = ^() {
        interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    };
    if ([NSThread isMainThread]) {
        statusBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), statusBlock);
    }
    
    AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
    dispatch_async(self.sessionQueue, ^{
        [self.session beginConfiguration];
        
        NSError *error = nil;
        
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        AVCaptureDevice *captureDevice = [devices firstObject];
        
        for (AVCaptureDevice *device in devices) {
            if ([device position] == AVCaptureDevicePositionFront) {
                captureDevice = device;
                break;
            }
        }
        AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        
        [self.session removeInput:self.videoCaptureDeviceInput];
        if ([self.session canAddInput:captureDeviceInput]) {
            [self.session addInput:captureDeviceInput];
            
            self.videoCaptureDeviceInput = captureDeviceInput;
            [self.previewLayer.connection setVideoOrientation:orientation];
        }
        
        [self.session commitConfiguration];
    });
}

- (void)setUpCaptureSessionOutput
{
    dispatch_async(self.sessionQueue, ^{
        [self.session beginConfiguration];
        
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        output.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
        
        if ([self.session canAddOutput:output]) {
            [self.session addOutput:output];
        }

        self.sampleBufferCallbackQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [output setSampleBufferDelegate:self queue:self.sampleBufferCallbackQueue];
        
        AVCaptureConnection *conn = [output connectionWithMediaType:AVMediaTypeVideo];
        [conn setVideoOrientation:AVCaptureVideoOrientationPortrait];

        [self.session commitConfiguration];
    });
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    FIRVisionDetectorImageOrientation orientation;
    
    AVCaptureDevicePosition devicePosition = AVCaptureDevicePositionFront;
    UIDeviceOrientation deviceOrientation = UIDevice.currentDevice.orientation;
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            if (devicePosition == AVCaptureDevicePositionFront) {
                orientation = FIRVisionDetectorImageOrientationLeftTop;
            } else {
                orientation = FIRVisionDetectorImageOrientationRightTop;
            }
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (devicePosition == AVCaptureDevicePositionFront) {
                orientation = FIRVisionDetectorImageOrientationBottomLeft;
            } else {
                orientation = FIRVisionDetectorImageOrientationTopLeft;
            }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (devicePosition == AVCaptureDevicePositionFront) {
                orientation = FIRVisionDetectorImageOrientationRightBottom;
            } else {
                orientation = FIRVisionDetectorImageOrientationLeftBottom;
            }
            break;
        case UIDeviceOrientationLandscapeRight:
            if (devicePosition == AVCaptureDevicePositionFront) {
                orientation = FIRVisionDetectorImageOrientationTopRight;
            } else {
                orientation = FIRVisionDetectorImageOrientationBottomRight;
            }
            break;
        default:
            orientation = FIRVisionDetectorImageOrientationTopLeft;
            break;
    }
    
    FIRVisionImageMetadata *metadata = [[FIRVisionImageMetadata alloc] init];
    metadata.orientation = orientation;

    UIImage *image = [ImageUtils imageFromSampleBufferRef:sampleBuffer];
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithBuffer:sampleBuffer];
    visionImage.metadata = metadata;
    
    [self.faceDetector processImage:visionImage completion:^(NSArray<FIRVisionFace *> *faces, NSError *error) {
        if (error != nil) {
            return;
        } else if (faces != nil) {
            [self onDetectFaces:faces visionImage:image];
        }
    }];
}

- (void)onDetectFaces:(NSArray<FIRVisionFace *> *)faces visionImage:(UIImage *)image
{
    std::set<long> trackingIDs;
    for (FIRVisionFace *face in faces) {
        if ([face hasTrackingID] != YES) {
            continue;
        }
        long trackingID = [face trackingID];
        trackingIDs.insert(trackingID);

        if (rppgMap.find(trackingID) == rppgMap.end()) {
            RPPG rppg;
            rppg.load(xminay, 0.001, 1, 5, 5);
            rppgMap[trackingID] = rppg;
        }
        
        RPPG& rppg = rppgMap[trackingID];

        FIRVisionFaceContour *leftEyebrowTop = [face contourOfType:FIRFaceContourTypeLeftEyebrowTop];
        FIRVisionFaceContour *leftEyebrowBottom = [face contourOfType:FIRFaceContourTypeLeftEyebrowBottom];
        FIRVisionFaceContour *rightEyebrowTop = [face contourOfType:FIRFaceContourTypeRightEyebrowTop];
        FIRVisionFaceContour *rightEyebrowBottom = [face contourOfType:FIRFaceContourTypeRightEyebrowBottom];
        FIRVisionFaceContour *leftEye = [face contourOfType:FIRFaceContourTypeLeftEye];
        FIRVisionFaceContour *rightEye = [face contourOfType:FIRFaceContourTypeRightEye];
        FIRVisionFaceContour *faceOval = [face contourOfType:FIRFaceContourTypeFace];

        if (leftEyebrowTop == nil ||
            leftEyebrowBottom == nil ||
            rightEyebrowTop == nil ||
            rightEyebrowBottom == nil ||
            leftEye == nil ||
            rightEye == nil ||
            faceOval == nil) {
            continue;
        }
        
        FIRVisionPoint *ltID = [faceOval.points lastObject];
        FIRVisionPoint *lbID = [leftEyebrowTop.points lastObject];
        FIRVisionPoint *rtID = [faceOval.points firstObject];
        FIRVisionPoint *rbID = [rightEyebrowTop.points lastObject];
        
        if (ltID == nil || lbID == nil || rtID == nil || rbID == nil) {
            continue;
        }

        CGPoint rt = CGPointMake([ltID.x floatValue], [ltID.y floatValue]);
        CGPoint rb = CGPointMake([lbID.x floatValue], [lbID.y floatValue]);
        CGPoint lt = CGPointMake([rtID.x floatValue], [rtID.y floatValue]);
        CGPoint lb = CGPointMake([rbID.x floatValue], [rbID.y floatValue]);
        
        lt.x = (lt.x + lb.x) / 2.0f;
        lt.y = (lt.y + lb.y) / 2.0f;
        rt.x = (rt.x + rb.x) / 2.0f;
        rt.y = (rt.y + rb.y) / 2.0f;

        [self onFacesDetected:[NSNumber numberWithInteger:[face trackingID]] lt:lt lb:lb rt:rt rb:rb];
        
        cv::Mat warpedMat = [ImageUtils warpImage:image lt:lt lb:lb rt:rt rb:rb];
        
        cv::Scalar means = [ImageUtils getSufaceMean:warpedMat];

        int time = (cv::getTickCount()*1000.0)/cv::getTickFrequency();
        if (rppg.processFrame(means, time)) {
            [self onHeartRate:[NSNumber numberWithInteger:[face trackingID]]
                  withMeanBpm:[NSNumber numberWithDouble:rppg.getMeanBpm()]
                   withMaxBpm:[NSNumber numberWithDouble:rppg.getMaxBpm()]
                   withMinBpm:[NSNumber numberWithDouble:rppg.getMinBpm()]];
        }

        UIImage *warpedImage = [ImageUtils UIImageFromCVMat:warpedMat];
        [self.extView superview].frame = CGRectMake(0, 0, 128, 128);
        self.extView.frame = [self.extView superview].bounds;
        [self.extView setImage:warpedImage];
    }
    
    for (auto it : rppgMap) {
        if (trackingIDs.find(it.first) == trackingIDs.end()) {
            it.second.invalidateFace();
        }
    }
}

- (void)onFacesDetected:(NSNumber *)trackingID lt:(CGPoint)lt lb:(CGPoint)lb rt:(CGPoint)rt rb:(CGPoint)rb
{
    if (_onFacesDetected) {
        _onFacesDetected(@{
                           @"trackingID": trackingID,
                           @"lt": @{
                                   @"x": [NSNumber numberWithFloat: lt.x],
                                   @"y": [NSNumber numberWithFloat: lt.y]
                                   },
                           @"lb": @{
                                   @"x": [NSNumber numberWithFloat: lb.x],
                                   @"y": [NSNumber numberWithFloat: lb.y]
                                   },
                           @"rt": @{
                                   @"x": [NSNumber numberWithFloat: rt.x],
                                   @"y": [NSNumber numberWithFloat: rt.y]
                                   },
                           @"rb": @{
                                   @"x": [NSNumber numberWithFloat: rb.x],
                                   @"y": [NSNumber numberWithFloat: rb.y]
                                   }
                           });
    }
}

- (void)onHeartRate:(NSNumber *)trackingID withMeanBpm:(NSNumber *)meanBpm withMaxBpm:(NSNumber *)maxBpm withMinBpm:(NSNumber *)minBpm
{
    if (_onHeartRate) {
        _onHeartRate(@{
                       @"trackingID": trackingID,
                       @"meanBpm": meanBpm,
                       @"maxBpm": maxBpm,
                       @"minBpm": minBpm
                       });
    }
}

@end
