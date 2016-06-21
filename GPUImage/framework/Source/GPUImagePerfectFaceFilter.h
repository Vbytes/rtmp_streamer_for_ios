//
//  GPUImageBeautifyFilter.h
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/28.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "GPUImage.h"
#import "GPUImageOverlayAndWhiterFilter.h"
#import "GPUImageSubtractionFilter.h"

@interface GPUImagePerfectFaceFilter : GPUImageFilterGroup {
    GPUImageBilateralFilter *bilateralFilter;
    GPUImageSubtractionFilter *SubtractionFilter;
    GPUImageGaussianBlurFilter *GaussianCopyFilter1;
    GPUImageGaussianBlurFilter *GaussianFilter;
    GPUImageOverlayAndWhiterFilter *OverlayAndWhiterFilter;
}

@end
