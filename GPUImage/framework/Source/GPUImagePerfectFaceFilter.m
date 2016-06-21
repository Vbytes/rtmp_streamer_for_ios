//
//  GPUImageBeautifyFilter.m
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/28.
//  Copyright © 2016年 guikz. All rights reserved.
//
#import "GPUImagePerfectFaceFilter.h"

@implementation GPUImagePerfectFaceFilter

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    // First pass: face smoothing filter
    bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    bilateralFilter.distanceNormalizationFactor = 4.0;
    [self addFilter:bilateralFilter];

    GaussianCopyFilter1 = [[GPUImageGaussianBlurFilter alloc] init];
    GaussianCopyFilter1.blurRadiusInPixels = 0;
    [self addFilter:GaussianCopyFilter1];
    
    SubtractionFilter = [[GPUImageSubtractionFilter alloc] init];
    [GaussianCopyFilter1 addTarget:SubtractionFilter];
    [bilateralFilter addTarget:SubtractionFilter];
    
    GaussianFilter = [[GPUImageGaussianBlurFilter alloc] init];
    GaussianFilter.blurRadiusInPixels = 2;
    [SubtractionFilter addTarget:GaussianFilter];

    OverlayAndWhiterFilter = [[GPUImageOverlayAndWhiterFilter alloc] init];
    [GaussianCopyFilter1 addTarget:OverlayAndWhiterFilter];
    [GaussianFilter addTarget:OverlayAndWhiterFilter];
    
        self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,GaussianCopyFilter1,SubtractionFilter,OverlayAndWhiterFilter,nil];
        self.terminalFilter = OverlayAndWhiterFilter;
//
//    self.initialFilters = [NSArray arrayWithObjects:bilateralFilter,nil];
//    self.terminalFilter = bilateralFilter;
    
    
    return self;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
        if (currentFilter != self.inputFilterToIgnoreForUpdates)
        {
//            if (currentFilter == combinationFilter) {
//                textureIndex = 2;
//            }
            [currentFilter newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (void)setInputFramebuffer:(GPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    for (GPUImageOutput<GPUImageInput> *currentFilter in self.initialFilters)
    {
//        if (currentFilter == combinationFilter) {
//            textureIndex = 2;
//        }
        [currentFilter setInputFramebuffer:newInputFramebuffer atIndex:textureIndex];
    }
}

@end
