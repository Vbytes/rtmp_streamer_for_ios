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

#import <videocore/api/iOS/StreamerSession.h>
#import <VideoCore/sources/adapter/AdapterSource.h>

#include <videocore/rtmp/RTMPSession.h>
#include <videocore/transforms/RTMP/AACPacketizer.h>
#include <videocore/transforms/RTMP/H264Packetizer.h>
#include <videocore/transforms/Split.h>
#include <videocore/transforms/AspectTransform.h>
#include <videocore/transforms/PositionTransform.h>

#ifdef __APPLE__
#   include <videocore/mixers/Apple/AudioMixer.h>
#   include <videocore/transforms/Apple/MP4Multiplexer.h>
#   include <videocore/transforms/Apple/H264Encode8.h>
#   include <videocore/sources/Apple/PixelBufferSource.h>
#   ifdef TARGET_OS_IPHONE
#       include <videocore/sources/iOS/CameraSource.h>
#       include <videocore/sources/iOS/MicSource.h>
#       //include <videocore/mixers/iOS/GLESVideoMixer.h>
#       include <videocore/transforms/iOS/AACEncode.h>
#       include <videocore/transforms/iOS/H264Encode.h>

#   else /* OS X */

#   endif
#else
#   include <videocore/mixers/GenericAudioMixer.h>
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


#include <sstream>


static const int kMinVideoBitrate = 128000;

namespace videocore { namespace simpleApi {

    using PixelBufferCallback = std::function<void(const uint8_t* const data,
                                                   size_t size)> ;

    class PixelBufferOutput : public IOutput
    {
    public:
        PixelBufferOutput(PixelBufferCallback callback)
        : m_callback(callback) {};

        void pushBuffer(const uint8_t* const data,
                        size_t size,
                        IMetadata& metadata)
        {
            m_callback(data, size);
        }

    private:

        PixelBufferCallback m_callback;
    };
}
}

@interface StreamerSession()
{

    //VCPreviewView* _previewView;

    std::shared_ptr<videocore::simpleApi::PixelBufferOutput> m_pbOutput;
    std::shared_ptr<videocore::iOS::MicSource>               m_micSource;
    std::shared_ptr<videocore::iOS::AdapterSource>           m_adapterCameraSoucre;
    
    std::shared_ptr<videocore::Apple::PixelBufferSource>     m_pixelBufferSource;
    
    std::shared_ptr<videocore::AspectTransform>   m_aspectTransform;
    std::shared_ptr<videocore::PositionTransform> m_positionTransform;

    std::shared_ptr<videocore::IAudioMixer> m_audioMixer;
    std::shared_ptr<videocore::ITransform>  m_h264Encoder;
    std::shared_ptr<videocore::ITransform>  m_aacEncoder;
    std::shared_ptr<videocore::ITransform>  m_h264Packetizer;
    std::shared_ptr<videocore::ITransform>  m_aacPacketizer;

    std::shared_ptr<videocore::Split>       m_aacSplit;
    std::shared_ptr<videocore::Split>       m_h264Split;
    std::shared_ptr<videocore::Apple::MP4Multiplexer> m_muxer;

    std::shared_ptr<videocore::IOutputSession> m_outputSession;


    // properties

    dispatch_queue_t _graphManagementQueue;
    
    dispatch_semaphore_t _globaldaemonSem;
    dispatch_queue_t _globaldaemonQueue;

    CGSize _videoSize;
    int    _bitrate;

    int    _fps;
    int    _bpsCeiling;
    int    _estimatedThroughput;

    BOOL   _useInterfaceOrientation;
    float  _videoZoomFactor;
    int    _audioChannelCount;
    float  _audioSampleRate;
    float  _micGain;

    VCCameraState _cameraState;

    VCSessionState _rtmpSessionState;


    BOOL _useAdaptiveBitrate;



}
@property (nonatomic, readwrite) VCSessionState rtmpSessionState;
@property (nonatomic,assign) NSString* reconnectURL;
@property (nonatomic,assign) NSString* reconnectkey;
- (void) setupGraph;
-(void) restartRtmpSession;  //由于网络中断，恢复推流客户端
@end

@implementation StreamerSession
@dynamic videoSize;
@dynamic bitrate;
@dynamic fps;
@dynamic useInterfaceOrientation;

@dynamic cameraState;

@dynamic rtmpSessionState;

@dynamic audioChannelCount;
@dynamic audioSampleRate;
@dynamic micGain;

@dynamic useAdaptiveBitrate;
@dynamic estimatedThroughput;

@synthesize reconnectURL;
@synthesize reconnectkey;

// -----------------------------------------------------------------------------
//  Properties Methods
// -----------------------------------------------------------------------------
#pragma mark - Properties
- (CGSize) videoSize
{
    return _videoSize;
}
- (void) setVideoSize:(CGSize)videoSize
{
    _videoSize = videoSize;

}
- (int) bitrate
{
    return _bitrate;
}
- (void) setBitrate:(int)bitrate
{
    _bitrate = bitrate;
}
- (int) fps
{
    return _fps;
}
- (void) setFps:(int)fps
{
    _fps = fps;
}
- (BOOL) useInterfaceOrientation
{
    return _useInterfaceOrientation;
}


- (void) setRtmpSessionState:(VCSessionState)rtmpSessionState
{
    _rtmpSessionState = rtmpSessionState;
    if (NSOperationQueue.currentQueue != NSOperationQueue.mainQueue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // trigger in main thread, avoid autolayout engine exception
            if(self.delegate) {
                [self.delegate connectionStatusChanged:rtmpSessionState];
            }
        });
    } else {
        if (self.delegate) {
            [self.delegate connectionStatusChanged:rtmpSessionState];
        }
    }
}
- (VCSessionState) rtmpSessionState
{
    return _rtmpSessionState;
}

- (void) setAudioChannelCount:(int)channelCount
{
    _audioChannelCount = MAX(1, MIN(channelCount, 2));

    if(m_audioMixer) {
        m_audioMixer->setChannelCount(_audioChannelCount);
    }
}
- (int) audioChannelCount
{
    return _audioChannelCount;
}
- (void) setAudioSampleRate:(float)sampleRate
{

    _audioSampleRate = (sampleRate > 33075 ? 44100 : 22050); // We can only support 44100 / 22050 with AAC + RTMP
    if(m_audioMixer) {
        m_audioMixer->setFrequencyInHz(sampleRate);
    }
}
- (float) audioSampleRate
{
    return _audioSampleRate;
}
- (void) setMicGain:(float)micGain
{
    if(m_audioMixer) {
        //增益
        m_audioMixer->setSourceGain(m_micSource, micGain);
        _micGain = micGain;
    }
}
- (float) micGain
{
    return _micGain;
}



- (BOOL) useAdaptiveBitrate {
    return _useAdaptiveBitrate;
}
- (void) setUseAdaptiveBitrate:(BOOL)useAdaptiveBitrate {
    _useAdaptiveBitrate = useAdaptiveBitrate;
    _bpsCeiling = _bitrate;
}
- (int) estimatedThroughput {
    return _estimatedThroughput;
}
// -----------------------------------------------------------------------------
//  Public Methods
// -----------------------------------------------------------------------------
#pragma mark - Public Methods
// -----------------------------------------------------------------------------

- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
{
    if((self = [super init])) {
        [self initInternalWithVideoSize:videoSize
                              frameRate:fps
                                bitrate:bps
                useInterfaceOrientation:NO
                            cameraState:VCCameraStateBack
                             aspectMode:VCAspectModeFit];

    }
    return self;
}

- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation
{
    if (( self = [super init] ))
    {
        [self initInternalWithVideoSize:videoSize
                              frameRate:fps
                                bitrate:bps
                useInterfaceOrientation:useInterfaceOrientation
                            cameraState:VCCameraStateBack
                             aspectMode:VCAspectModeFit];
    }
    return self;
}

- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation
                       cameraState:(VCCameraState) cameraState
{
    if (( self = [super init] ))
    {
        [self initInternalWithVideoSize:videoSize
                              frameRate:fps
                                bitrate:bps
                useInterfaceOrientation:useInterfaceOrientation
                            cameraState:cameraState
                             aspectMode:VCAspectModeFit];
    }
    return self;
}

- (instancetype) initWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation
                       cameraState:(VCCameraState) cameraState
                        aspectMode:(VCAspectMode)aspectMode
{
    if (( self = [super init] ))
    {
        [self initInternalWithVideoSize:videoSize
                              frameRate:fps
                                bitrate:bps
                useInterfaceOrientation:useInterfaceOrientation
                            cameraState:cameraState
                             aspectMode:aspectMode];
    }
    return self;
}



- (void) initInternalWithVideoSize:(CGSize)videoSize
                         frameRate:(int)fps
                           bitrate:(int)bps
           useInterfaceOrientation:(BOOL)useInterfaceOrientation
                       cameraState:(VCCameraState) cameraState
                        aspectMode:(VCAspectMode)aspectMode
{
    self.bitrate = bps;
    self.videoSize = videoSize;
    self.fps = fps;
    _useInterfaceOrientation = useInterfaceOrientation;
    self.micGain = 1.f;
    self.audioChannelCount = 2;
    self.audioSampleRate = 44100.;
    self.useAdaptiveBitrate = NO;


    _cameraState = cameraState;
   

    _graphManagementQueue = dispatch_queue_create("com.videocore.session.graph", 0);
    _globaldaemonQueue=dispatch_queue_create("com.network.session.daemon", 0); //守护进程信号
   // _globaldaemonQueue=dispatch_get_global_queue(0,0) ;//守护进程信号
    _globaldaemonSem=dispatch_semaphore_create(0);
    
    __block StreamerSession* bSelf = self;

    dispatch_async(_graphManagementQueue, ^{
        [bSelf setupGraph];
    });
}

- (void) dealloc
{
    [self endRtmpSession];
    m_audioMixer.reset();
    m_aspectTransform.reset();
    m_positionTransform.reset();
    m_micSource.reset();
    m_adapterCameraSoucre.reset();
    m_pbOutput.reset();

    
    dispatch_release(_graphManagementQueue);
    dispatch_release(_globaldaemonQueue);
    dispatch_release(_globaldaemonSem);
    [super dealloc];
}
-(void)deamon{
    
    NSLog(@"守护线程启动，开始等待！");
    dispatch_semaphore_wait(_globaldaemonSem,DISPATCH_TIME_FOREVER);
    [self restartRtmpSession];
    NSLog(@"守护线程工作完成！");
    
    
}


- (void) startRtmpSessionWithURL:(NSString *)rtmpUrl
                    andStreamKey:(NSString *)streamKey
{

    self.reconnectURL=rtmpUrl;
    self.reconnectkey=streamKey;
    __block StreamerSession* bSelf = self;

    dispatch_async(_graphManagementQueue, ^{
        [bSelf startSessionInternal:rtmpUrl streamKey:streamKey];
    });
}
- (void) startSessionInternal: (NSString*) rtmpUrl
                    streamKey: (NSString*) streamKey
{
    std::stringstream uri ;
    uri << (rtmpUrl ? [rtmpUrl UTF8String] : "") << "/" << (streamKey ? [streamKey UTF8String] : "");
    
    m_outputSession.reset(
                          new videocore::RTMPSession ( uri.str(),
                                                      [=](videocore::RTMPSession& session,
                                                          ClientState_t state) {

                                                          DLog("ClientState: %d\n", state);

                                                          switch(state) {

                                                              case kClientStateConnected:
                                                                  self.rtmpSessionState = VCSessionStateStarting;
                                                                  break;
                                                              case kClientStateSessionStarted:
                                                              {

                                                                  __block StreamerSession* bSelf = self;
                                                                  dispatch_async(_graphManagementQueue, ^{
                                                                      [bSelf addEncodersAndPacketizers];
                                                                  });
                                                              }
                                                                  self.rtmpSessionState = VCSessionStateStarted;

                                                                  break;
                                                              case kClientStateError:
                                                              {
                                                                  self.rtmpSessionState = VCSessionStateError;
                                                                  __block StreamerSession* bSelf = self;
                                                                  dispatch_async(_graphManagementQueue, ^{
                                                                      [bSelf endRtmpSession];
                                                                  });
                                                                 
                                                                  break;
                                                              }
                                                              case kClientStateNotConnected:  //掉线
                                                              {
                                                                  self.rtmpSessionState = VCSessionStateEnded;
                                                                  __block StreamerSession* bSelf = self;
                                                                  dispatch_async(_graphManagementQueue, ^{
                                                                     [bSelf restartRtmpSession];
                                                                   });
                                                                  break;
                                                              }
                                                              default:
                                                                  break;

                                                          }

                                                      }) );
    StreamerSession* bSelf = self;

    _bpsCeiling = _bitrate;

    if ( self.useAdaptiveBitrate ) {
        //如果是自适应码率则修改初始码率的值512kb/s
        _bitrate = 512000;
    }

    m_outputSession->setBandwidthCallback([=](float vector, float predicted, float inst,int buffersize,int            lost)
                                          {

                                              bSelf->_estimatedThroughput = predicted;
                                              auto video = std::dynamic_pointer_cast<videocore::IEncoder>( bSelf->m_h264Encoder );
                                              auto audio = std::dynamic_pointer_cast<videocore::IEncoder>( bSelf->m_aacEncoder );
                                              if(video && audio && bSelf.useAdaptiveBitrate) {

                                                  if ([bSelf.delegate respondsToSelector:@selector(detectedNetwork:lostPacketSize:)]) {
                                                      [bSelf.delegate detectedNetwork:buffersize lostPacketSize:lost];
                                                  }
                                                  if ([bSelf.delegate respondsToSelector:@selector(detectedThroughput:videoRate:audioRate:)]) {
                                                      [bSelf.delegate detectedThroughput:inst
                                                                      videoRate:video->bitrate()
                                                                      audioRate:audio->bitrate()];
                                                  }


                                                  int videoBr = 0;

                                                  if(vector != 0) {

                                                      vector = vector < 0 ? -1 : 1 ;

                                                      videoBr = video->bitrate();

                                                      if (audio) {

                                                          if ( videoBr > 500000 ) {
                                                              audio->setBitrate(128000);
                                                          } else if (videoBr <= 500000 && videoBr > 250000){
                                                              audio->setBitrate(96000);
                                                          } else {
                                                              audio->setBitrate(80000);
                                                          }
                                                      }
                                                      
                                                      //最小码率kMinvideoBitrate 最大码率 bpsCeiling
                                                      if(videoBr > 1152000) {
                                                          video->setBitrate(std::min(int((videoBr / 384000 + vector )) * 384000, bSelf->_bpsCeiling) );
                                                      }
                                                      else if( videoBr > 512000 ) {
                                                          video->setBitrate(std::min(int((videoBr / 128000 + vector )) * 128000, bSelf->_bpsCeiling) );
                                                      }
                                                      else if( videoBr > 128000 ) {
                                                          video->setBitrate(std::min(int((videoBr / 64000 + vector )) * 64000, bSelf->_bpsCeiling) );
                                                      } else {
                                                          video->setBitrate(std::max(std::min(int((videoBr / 64000 + vector )) * 64000, bSelf->_bpsCeiling), kMinVideoBitrate) );
                                                      }

                                                  } /* if(vector != 0) */
                                                  printf("\n(%f) AudioBR: %d VideoBR: %d (%f)\n", vector, audio->bitrate(), video->bitrate(), inst);

                                              } /* if(video && audio && m_adaptiveBREnabled) */


                                          });

    videocore::RTMPSessionParameters_t sp ( 0. );

    sp.setData(self.videoSize.width,
               self.videoSize.height,
               1. / static_cast<double>(self.fps),
               self.bitrate,
               self.audioSampleRate,
               (self.audioChannelCount == 2));

    m_outputSession->setSessionParameters(sp);
}
- (void) endRtmpSession
{
    NSLog(@"endRtmpSession begin");
    m_h264Packetizer.reset();
    m_aacPacketizer.reset();

    m_h264Encoder.reset();
    m_aacEncoder.reset();

    m_outputSession.reset();

    _bitrate = _bpsCeiling;

    self.rtmpSessionState = VCSessionStateEnded;
    NSLog(@"endRtmpSession end");
    
}
-(void) restartRtmpSession
{

    [self endRtmpSession];
    NSLog(@"begin restart new stream!");
    [self startRtmpSessionWithURL:self.reconnectURL
                     andStreamKey:self.reconnectkey];
    NSLog(@"start one new stream successed!");
}

// -----------------------------------------------------------------------------
//  Private Methods
// -----------------------------------------------------------------------------
#pragma mark - Private Methods


- (void) setupGraph
{
    const double frameDuration = 1. / static_cast<double>(self.fps);

    {
        // Add audio mixer
        const double aacPacketTime = 1024. / self.audioSampleRate;

        m_audioMixer = std::make_shared<videocore::Apple::AudioMixer>(self.audioChannelCount,
                                                                      self.audioSampleRate,
                                                                      16,
                                                                      aacPacketTime);


        // The H.264 Encoder introduces about 2 frames of latency, so we will set the minimum audio buffer duration to 2 frames.
        m_audioMixer->setMinimumBufferDuration(frameDuration*2);
    }
#ifdef __APPLE__
#ifdef TARGET_OS_IPHONE


    {
        // Add video mixer
       /* m_videoMixer = std::make_shared<videocore::iOS::GLESVideoMixer>(self.videoSize.width,
                                                                        self.videoSize.height,
                                                                        frameDuration);*/

    }

       //音视频混合
#else
#endif // TARGET_OS_IPHONE
#endif // __APPLE__

    // Create sources
    {
        
        m_adapterCameraSoucre=std::make_shared<videocore::iOS::AdapterSource>(self.videoSize.width,
                                                                              self.videoSize.height,'BGRA',frameDuration);
       // m_adapterCameraSoucre->setOutput(m_videoMixer);
        
    }
    
    {
        // Add mic source
        m_micSource = std::make_shared<videocore::iOS::MicSource>(self.audioSampleRate, self.audioChannelCount);
        m_micSource->setOutput(m_audioMixer);

        const auto epoch = std::chrono::steady_clock::now();

        m_audioMixer->setEpoch(epoch);
        m_adapterCameraSoucre->setEpoch(epoch);
       // m_videoMixer->setEpoch(epoch);

        m_audioMixer->start();
       // m_videoMixer->start();
        m_adapterCameraSoucre->start();

    }
}
- (void) addEncodersAndPacketizers
{
    int ctsOffset = 2000 / self.fps; // 2 * frame duration
    {
        // Add encoders

        m_aacEncoder = std::make_shared<videocore::iOS::AACEncode>(self.audioSampleRate, self.audioChannelCount, 96000);
        if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            // If >= iOS 8.0 use the VideoToolbox encoder that does not write to disk.
            m_h264Encoder = std::make_shared<videocore::Apple::H264Encode>(self.videoSize.width,
                                                                           self.videoSize.height,
                                                                           self.fps,
                                                                           self.bitrate,
                                                                           false,
                                                                           ctsOffset);
        } else {
            m_h264Encoder =std::make_shared<videocore::iOS::H264Encode>(self.videoSize.width,
                                                                        self.videoSize.height,
                                                                        self.fps,
                                                                        self.bitrate);
        }
        m_audioMixer->setOutput(m_aacEncoder);
        m_adapterCameraSoucre->setOutput(m_h264Encoder);
       
        

    }
    {
        m_aacSplit = std::make_shared<videocore::Split>();
        m_h264Split = std::make_shared<videocore::Split>();
        m_aacEncoder->setOutput(m_aacSplit);
        m_h264Encoder->setOutput(m_h264Split);

    }
    {
        m_h264Packetizer = std::make_shared<videocore::rtmp::H264Packetizer>(ctsOffset);
        m_aacPacketizer = std::make_shared<videocore::rtmp::AACPacketizer>(self.audioSampleRate, self.audioChannelCount, ctsOffset);

        m_h264Split->setOutput(m_h264Packetizer);
        m_aacSplit->setOutput(m_aacPacketizer);

    }
    {
        /*m_muxer = std::make_shared<videocore::Apple::MP4Multiplexer>();
         videocore::Apple::MP4SessionParameters_t parms(0.) ;
         std::string file = [[[self applicationDocumentsDirectory] stringByAppendingString:@"/output.mp4"] UTF8String];
         parms.setData(file, self.fps, self.videoSize.width, self.videoSize.height);
         m_muxer->setSessionParameters(parms);
         m_aacSplit->setOutput(m_muxer);
         m_h264Split->setOutput(m_muxer);*/
    }
    //打包发送

    m_h264Packetizer->setOutput(m_outputSession);
    m_aacPacketizer->setOutput(m_outputSession);

    
}
- (void) addPixelBufferSource: (UIImage*) image
                     withRect:(CGRect)rect {
    CGImageRef ref = [image CGImage];
    
    m_pixelBufferSource = std::make_shared<videocore::Apple::PixelBufferSource>(CGImageGetWidth(ref),
                                                                                CGImageGetHeight(ref),
                                                                                'BGRA');
    
    NSUInteger width = CGImageGetWidth(ref);
    NSUInteger height = CGImageGetHeight(ref);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), ref);
    CGContextRelease(context);
    
    //m_pixelBufferSource->setOutput(m_videoMixer);
  //  m_videoMixer->registerSource(m_pixelBufferSource);
    m_pixelBufferSource->pushPixelBuffer(rawData, width * height * 4);
    
    free(rawData);
    
}
- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(void) addRawBufferDataSource:(const char* )data
                        withLen:(int)dataLen
{
     if(m_adapterCameraSoucre)
     {
         m_adapterCameraSoucre->PollRawDatas(data,dataLen);
     }
    
}


-(int)getVersion{
    return 1;
}
-(void) testrestart
{
   
    __block StreamerSession* bSelf = self;
    dispatch_async(_graphManagementQueue, ^{
        [bSelf restartRtmpSession];
    });
}

@end
