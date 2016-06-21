/*

 Video Core
 Copyright (c) 2014 James G. Hurley

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

 */

/*!
 *  A simple Objective-C Session API that will create an RTMP session using the
 *  device's camera(s) and microphone.
 *
 */

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class StreamerSession;

typedef NS_ENUM(NSInteger, VCSessionState)
{
    VCSessionStateNone,
    VCSessionStatePreviewStarted,
    VCSessionStateStarting,
    VCSessionStateStarted,
    VCSessionStateEnded,
    VCSessionStateError

};

typedef NS_ENUM(NSInteger, VCCameraState)
{
    VCCameraStateFront,
    VCCameraStateBack
};

typedef NS_ENUM(NSInteger, VCAspectMode)
{
    VCAspectModeFit,
    VCAscpectModeFill
};

//With new filters should add an enum here
typedef NS_ENUM(NSInteger, VCFilter) {
    VCFilterNormal,
    VCFilterGray,
    VCFilterInvertColors,
    VCFilterSepia,
    VCFilterFisheye,
    VCFilterGlow
};
//delegate status of cooonection
@protocol StreamerSessionDelegate <NSObject>
@required
- (void) connectionStatusChanged: (VCSessionState) sessionState;
@optional
//- (void) didAddCameraSource:(StreamerSession*)session;

- (void) detectedNetwork: (NSInteger) bufferSize
                          lostPacketSize:(NSInteger)losts;
- (void) detectedThroughput: (NSInteger) throughputInBytesPerSecond
                                         videoRate:(NSInteger) videorate
                                         audioRate:(NSInteger) audiorate;
@end

@interface StreamerSession : NSObject

@property (nonatomic, readonly) VCSessionState rtmpSessionState;
//@property (nonatomic, strong, readonly) UIView* previewView;

/*! Setters / Getters for session properties */
@property (nonatomic, assign) CGSize            videoSize;      // Change will not take place until the next RTMP Session
@property (nonatomic, assign) int               bitrate;        // Change will not take place until the next RTMP Session
@property (nonatomic, assign) int               fps;            // Change will not take place until the next RTMP Session
@property (nonatomic, assign, readonly) BOOL    useInterfaceOrientation;
@property (nonatomic, assign) VCCameraState cameraState;


@property (nonatomic, assign) int           audioChannelCount;
@property (nonatomic, assign) float         audioSampleRate;
@property (nonatomic, assign) float         micGain;        // [0..1]
@property (nonatomic, assign) CGPoint       focusPointOfInterest;   // (0,0) is top-left, (1,1) is bottom-right

@property (nonatomic, assign) BOOL          useAdaptiveBitrate;     /* Default is off */
@property (nonatomic, readonly) int         estimatedThroughput;    /* Bytes Per Second. */
@property (nonatomic, assign) VCAspectMode  aspectMode;


@property (nonatomic, assign) id<StreamerSessionDelegate> delegate;

// -----------------------------------------------------------------------------
- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps;

// -----------------------------------------------------------------------------
- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation;

// -----------------------------------------------------------------------------
- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation
                       cameraState:(VCCameraState) cameraState;

// -----------------------------------------------------------------------------
- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation
                       cameraState:(VCCameraState) cameraState
                        aspectMode:(VCAspectMode) aspectMode;

// -----------------------------------------------------------------------------

- (void) startRtmpSessionWithURL:(NSString*) rtmpUrl
                    andStreamKey:(NSString*) streamKey;

- (void) endRtmpSession;



-(void) addRawBufferDataSource:(const char*)data
                    withLen:(int)dataLen ;
-(int)getVersion;
-(void) testrestart;
@end
