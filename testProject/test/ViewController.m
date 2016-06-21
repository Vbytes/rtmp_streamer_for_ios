//
//  ViewController.m
//  MoonStoneStreamer
//
//  Created by duskash on 16/3/31.
//  Copyright © 2016年 duskash. All rights reserved.
//

#import "ViewController.h"


#import "IOSStreamer/GPUImageApi.h"
@interface ViewController ()<NetworkSessionDelegate>{}

@property(nonatomic,assign) SessionState lastState;
@property(nonatomic,retain) GPUImageApi*   GPUAPI;
@end

@implementation ViewController

@synthesize connectbtn;
@synthesize lastState;
- (void)viewDidLoad {
    [super viewDidLoad];
    [_tiptext setBackgroundColor:[UIColor clearColor]];
    [connectbtn setBackgroundColor:[UIColor clearColor]];

  //  CGSize sz = [[UIScreen mainScreen] bounds].size;
    //CGSize sz=CGSizeMake(640, 480);
    //CGSize sz=CGSizeMake(1440, 2560);
    _GPUAPI=[[GPUImageApi alloc] initWithCapture:self.view
                                 frameRate:20
                                 bitRate:1000000
                                 withResolution:Preset640x480];
             
   

    
    
    [_GPUAPI startPreview];
    _GPUAPI.delegate=self;
    
    _sliderbtn.minimumValue=0.0f;
    _sliderbtn.maximumValue=20.f;
    _sliderbtn.value=10.0f;

    lastState=SessionStateNone;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:)name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification:)name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
    
}
-(IBAction)streamConnect:(id)sender{
    switch(_GPUAPI.rtmpSessionState) {
     case SessionStateNone:
     case SessionStatePreviewStarted:
     case SessionStateEnded:
     case SessionStateError:
     
     [_GPUAPI BeginStream:@"rtmp://101.200.130.59:1936/live/livestream" andStreamKey:@""];
     break;
     default:
     [_GPUAPI EndStream];
     break;
     }
}
- (void) connectionStatusChanged:(SessionState) state
{
    self.lastState=state;
    switch(state) {
        case SessionStateStarting:
            [self.connectbtn setTitle:@"开始推流" forState:UIControlStateNormal];
            break;
        case SessionStateStarted:
            [self.connectbtn setTitle:@"停止推流" forState:UIControlStateNormal];
            
            break;
        default:
            [self.connectbtn setTitle:@"开始推流" forState:UIControlStateNormal];
            break;
        }

}
- (void) detectedNetwork: (NSInteger) bufferSize
          lostPacketSize:(NSInteger)losts
{
    NSString* str=[NSString stringWithFormat:@"BufferSize:%d Bytes\nLostBytes:%d Bytes",(int)bufferSize,(int)losts];
    dispatch_queue_t main=dispatch_get_main_queue();
    dispatch_async(main, ^{
        _labNetwork.numberOfLines=0;
        [ _labNetwork setText:str];
    });
    
}
-(void) detectedThroughput: (NSInteger) throughputInBytesPerSecond videoRate:(NSInteger) videorate  audioRate:(NSInteger)audiorate
{
    float perSec=((float)throughputInBytesPerSecond)/1000;
    float vr=((float)videorate)/1000;
    float ar=((float)audiorate)/1000;
    NSString* str=[NSString stringWithFormat:@"TotalBitRate:%.2f kb/s \nVideoRate:%.2f kb/s\nAudioRate:%.2f kb/s",perSec,vr,ar];
    dispatch_queue_t main=dispatch_get_main_queue();
    dispatch_async(main, ^{
        _labText.numberOfLines=0;
        [ _labText setText:str];
    });

   
    
    
}

-(IBAction)camaraToggle:(id)sender
{
    
    [_GPUAPI rotateCamera];

}
-(IBAction)FilterClick:(id)sender{
    static bool filterOn =true;
    filterOn = !filterOn;
     [_GPUAPI enableFaceFilter:filterOn];

}
-(IBAction)TorchClick:(id)sender{
   
    static bool On=false;
    On = !On;
    [_GPUAPI setTorch:On];
    
}


-(void)applicationDidBecomeActiveNotification:(NSNotification*)notification
{
   if(self.lastState==SessionStateStarted)
   {
       NSLog(@"恢复前台运行");
     [_GPUAPI BeginStream:@"rtmp://101.200.130.59:1936/live/livestream" andStreamKey:@""];
   }
     [UIApplication sharedApplication].idleTimerDisabled=YES;
}
-(void)applicationWillResignActive:(NSNotification*)notification
{
    if(self.lastState==SessionStateStarted)
    {
        NSLog(@"后台运行");
        [_GPUAPI EndStream];
        self.lastState=SessionStateStarted;
    }
     [UIApplication sharedApplication].idleTimerDisabled=NO;
}
@end
