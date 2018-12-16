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

@interface FacePulseDetector ()

@property (nonatomic, weak) RCTBridge *bridge;

@end

@implementation FacePulseDetectorManager

RCT_EXPORT_MODULE();

- (UIView *)view
{
    return [[FacePulseDetector alloc] initWithBridge];
}

@end
