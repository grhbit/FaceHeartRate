//
//  ImageUtils.h
//  faceheartrate
//
//  Created by alchemist on 16/12/2018.
//  Copyright © 2018 650 Industries, Inc. All rights reserved.
//

#import <opencv2/core/core.hpp>
#import <opencv2/opencv.hpp>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ImageUtils : NSObject

+ (UIImage *)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (UIImage *)warpImage:(UIImage *)image lt:(CGPoint)lt lb:(CGPoint)lb rt:(CGPoint)rt rb:(CGPoint)rb;

@end
