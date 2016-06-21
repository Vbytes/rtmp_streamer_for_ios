//
//  GPUImageApi.h
//  GPUImage
//
//  Created by songmm on 16/4/11.
//  Copyright © 2016年 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^AfterGetFrame)(const char* data,int dataLen);

typedef NS_ENUM(NSInteger, SessionState)
{
    SessionStateNone,
    SessionStatePreviewStarted,
    SessionStateStarting,
    SessionStateStarted,
    SessionStateEnded,
    SessionStateError
    
};
typedef NS_ENUM(NSInteger,Resolutions)
{
    Preset352x288,
    Preset640x480,
    Preset1280x720,
    Preset1920x1080
};

//网络状态session
@protocol NetworkSessionDelegate <NSObject>
@required
- (void) connectionStatusChanged: (SessionState) sessionState;
@optional

- (void) detectedNetwork: (NSInteger) bufferSize
                          lostPacketSize:(NSInteger)losts;
- (void) detectedThroughput: (NSInteger) throughputInBytesPerSecond
                                         videoRate:(NSInteger) videorate
                                         audioRate:(NSInteger) audiorate;
@end




@interface GPUImageApi : NSObject
@property (nonatomic, assign) id<NetworkSessionDelegate> delegate;
@property (nonatomic, readonly) SessionState rtmpSessionState;
-(void)APIVERSION;      //verbose the version of gpuimageapi

-(id) initWithCapture:(UIView*) parentView
                      frameRate:(int)fps
                      bitRate:(int)bps
                      withResolution:(Resolutions)preset;            //初始化

-(bool) startPreview;                                                //启动预览

-(bool) rotateCamera;                                                //摄像头切换

-(bool) setTorch:(bool)open;                                         //闪光灯设置

-(void) enableFaceFilter:(bool)open;                                //美颜开关设置

-(bool) BeginStream:(NSString*) rtmpUrl
                    andStreamKey:(NSString*) streamKey;             //启动推流
-(bool)EndStream;                                                   //关闭推流

@end
