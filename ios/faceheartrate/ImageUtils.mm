//
//  ImageUtils.m
//  faceheartrate
//
//  Created by alchemist on 16/12/2018.
//  Copyright © 2018 650 Industries, Inc. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage *)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef    buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = (uint8_t*)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef  cgImage;
    UIImage*    image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                          orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return image;
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (UIImage *)warpImage:(UIImage *)image lt:(CGPoint)lt lb:(CGPoint)lb rt:(CGPoint)rt rb:(CGPoint)rb
{
    cv::Mat rawData = [ImageUtils cvMatFromUIImage:image];
    
    cv::Point2f ptSrc[4];
    cv::Point2f ptDest[4];
    ptSrc[0] = cv::Point2f(lt.x, lt.y);
    ptSrc[1] = cv::Point2f(rt.x, rt.y);
    ptSrc[2] = cv::Point2f(rb.x, rb.y);
    ptSrc[3] = cv::Point2f(lb.x, lb.y);
    
    ptDest[0] = cv::Point2f(0, 0);
    ptDest[1] = cv::Point2f(256, 0);
    ptDest[2] = cv::Point2f(256, 256);
    ptDest[3] = cv::Point2f(0, 256);
    
    cv::Mat mat = cv::getPerspectiveTransform(ptSrc, ptDest);
    cv::Mat output = cv::Mat(256, 256, CV_8UC4);
    cv::warpPerspective(rawData, output, mat, output.size());
    
    UIImage *finalImage = [ImageUtils UIImageFromCVMat:output];
    
    return finalImage;
}

@end
