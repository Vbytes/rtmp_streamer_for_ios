//
//  GPUImageApi.m
//  GPUImage
//
//  Created by duskash on 16/4/11.
//  Copyright © 2016年 Brad Larson. All rights reserved.
//

#import "GPUImageApi.h"
#import "GPUImage.h"
#import "StreamerSession.h"


@interface GPUImageApi()<NSStreamDelegate>
{
    bool faceFilter;
    CGSize outputSize;
    id<NetworkSessionDelegate> _delegate;
    
}
@property(nonatomic, retain) GPUImageVideoCamera* videoCamera;

@property(nonatomic, retain) GPUImageBeautifyFilter* filter;

@property(nonatomic, retain) GPUImageView *filterView;
@property(nonatomic, retain)  GPUImageRawDataOutput* rawDataOutput;
@property(nonatomic, retain)  StreamerSession* session;

-(bool) setOutputCallBack:(AfterGetFrame)callback;
@end


@implementation GPUImageApi

@dynamic delegate;

-(id<NetworkSessionDelegate>) delegate{
    
    return _delegate;
}
-(void)setDelegate:(id<NetworkSessionDelegate>)delegate{
    
    if (self.session) {
        self.session.delegate=(id<StreamerSessionDelegate>)delegate;
       
    }
    _delegate=delegate;
}

- (SessionState) rtmpSessionState
{
    return (SessionState)self.session.rtmpSessionState;
}




-(void)APIVERSION{
    
    NSLog(@"API VERSION 1.0.0");
    return ;
}

- (id) initWithCapture:(UIView*) parentView
                       frameRate:(int)fps
                       bitRate:(int)bps
                       withResolution:(Resolutions)preset;
                        
{
    if (( self = [super init] ))
    {
        NSString* SessionPreset = nil;
        switch (preset) {
            case Preset352x288:
                outputSize=CGSizeMake(288, 352);
                SessionPreset = [[NSString alloc] initWithString:AVCaptureSessionPreset352x288];
                break;
            case Preset640x480:
                outputSize=CGSizeMake(480, 640);
                SessionPreset = [[NSString alloc] initWithString:AVCaptureSessionPreset640x480];
                break;
            case Preset1280x720:
                outputSize=CGSizeMake(720, 1280);
                SessionPreset = [[NSString alloc] initWithString:AVCaptureSessionPreset1280x720];
                break;
            case Preset1920x1080:
                outputSize=CGSizeMake(1080, 1920);
                SessionPreset = [[NSString alloc] initWithString:AVCaptureSessionPreset1920x1080];
                break;
            default:
                outputSize=CGSizeMake(480, 640);
                SessionPreset = [[NSString alloc] initWithString:AVCaptureSessionPreset640x480];
                break;
           }
        
        
        
            CGRect parentRt=[parentView bounds];
            self.videoCamera=[[GPUImageVideoCamera alloc] initWithSessionPreset: SessionPreset cameraPosition:AVCaptureDevicePositionBack];
            
            //  UIDeviceOrientationUnknown 设置摄像头方向为竖直方向
            self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

            [self.videoCamera setFrameRate:fps];
            
            //设置屏幕为平铺
            self.filterView = [[GPUImageView alloc] initWithFrame:parentRt];
            //self.filterView.fillMode=kGPUImageFillModeStretch;
            self.filterView.fillMode=kGPUImageFillModePreserveAspectRatioAndFill;
            [parentView addSubview:self.filterView];
            [parentView sendSubviewToBack:self.filterView];
            
        
            //美颜算法一
            self.filter=[[GPUImageBeautifyFilter alloc] init];
             //美颜算法二：有兴趣可以尝试
            //self.filter=[[GPUImagePerfectFaceFilter alloc] init];



        
            //是否启动美颜
            faceFilter = true;
            if (faceFilter) {
                [self.videoCamera addTarget:self.filter];
                [self.filter addTarget:self.filterView];
            } else {
                [self.videoCamera addTarget:self.filterView];
            }
        
            //最大码率1mbps
            self.session=[[StreamerSession alloc] initWithVideoSize:outputSize frameRate:fps bitrate:bps];
            //使用自适应码率
            self.session.useAdaptiveBitrate = TRUE;
        
            __block StreamerSession* weekSession=self.session;
            [self setOutputCallBack:^(const char* data,int dataLen){
                
                [weekSession addRawBufferDataSource:data withLen:dataLen];
            } ];
     
    }
    return self;
}

-(bool) setOutputCallBack:(AfterGetFrame)callback

{
    if(_rawDataOutput==nil)
    {
       _rawDataOutput= [[GPUImageRawDataOutput alloc] initWithImageSize:outputSize resultsInBGRAFormat:YES];
        
      if (faceFilter) {
          [self.filter addTarget:_rawDataOutput];
      } else {
          [self.videoCamera addTarget:_rawDataOutput];
      }
        
        
        __unsafe_unretained GPUImageRawDataOutput * weakOutput = _rawDataOutput;
 
        __block const char *outputBytes =NULL;
        int totalsize = outputSize.width * outputSize.height * 4;

        [_rawDataOutput setNewFrameAvailableBlock:^{
            [weakOutput lockFramebufferForReading];
            outputBytes = (const char*)[weakOutput rawBytesForImage];
  
            callback(outputBytes,totalsize);
    
            [weakOutput unlockFramebufferAfterReading];
        }];

        
        
        
    }
    else
    {
        return false;
    }
    return true;
}
-(bool) startPreview
{
    [self.videoCamera startCameraCapture];
    return true;
}
-(void)dealloc
{
    
    [self.videoCamera removeAllTargets];


}
-(bool) rotateCamera{
     [self.videoCamera rotateCamera];
    return true;
}
-(bool) setTorch:(bool)open {
    
    return [self.videoCamera setTorchOn:open];
}
-(void) enableFaceFilter:(bool)open{
    if(open==faceFilter) return ;
    if (open) {
        
        [self.videoCamera removeTarget:_rawDataOutput];
        [self.videoCamera removeTarget:self.filterView];
        
        [self.videoCamera addTarget:self.filter];
        [self.filter addTarget:self.filterView];
        [self.filter addTarget:_rawDataOutput];
        
    } else {
        [self.videoCamera removeTarget:self.filter];
        [self.filter removeTarget:_rawDataOutput];
        [self.filter removeTarget:self.filterView];
       

        [self.videoCamera addTarget:_rawDataOutput];
        [self.videoCamera addTarget:self.filterView];
    }
    faceFilter=open;
}

-(bool) BeginStream:(NSString*) rtmpUrl
                     andStreamKey:(NSString*) streamKey
{
    [self.session startRtmpSessionWithURL:rtmpUrl andStreamKey:streamKey];
    return true;
}
-(bool)EndStream{
    [self.session endRtmpSession];
    return true;
}


@end
