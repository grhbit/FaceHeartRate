//
//  FacePulseDetectorManager.m
//  faceheartrate
//
//  Created by Gwon Seonggwang on 15/12/2018.
//  Copyright © 2018. All rights reserved.
//

#import "FacePulseDetectorManager.h"
#import "FacePulseDetector.h"
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>

@implementation FacePulseDetectorManager

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();
RCT_EXPORT_VIEW_PROPERTY(onFacesDetected, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onHeartRate, RCTDirectEventBlock)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onFacesDetected", @"onHeartRate"];
}

- (UIView *)view
{
    return [[FacePulseDetector alloc] initWithBridge:self.bridge];
}

@end
