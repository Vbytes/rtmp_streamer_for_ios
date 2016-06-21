#import "GPUImageOverlayAndWhiterFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageOverlayAndWhiterFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp vec4 outputcolor;
     outputcolor.r = textureColor.r + textureColor2.r - 0.5;
     outputcolor.g = textureColor.g + textureColor2.g - 0.5;
     outputcolor.b = textureColor.b + textureColor2.b - 0.5;
     outputcolor.a = 1.0;
     outputcolor.r += 0.065 * (1.0 - (2.0 * outputcolor.r - 1.0)*(2.0 * outputcolor.r - 1.0));
     outputcolor.g += 0.065 * (1.0 - (2.0 * outputcolor.g - 1.0)*(2.0 * outputcolor.g - 1.0));
     outputcolor.b += 0.065 * (1.0 - (2.0 * outputcolor.b - 1.0)*(2.0 * outputcolor.b - 1.0));
     
     gl_FragColor = outputcolor;
     
 }
);

#else
NSString *const kGPUImageOverlayAndWhiterFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 //uniform float mixturePercent;
 
 void main()
 {
	 vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
	 
     vec4 outputcolor;
     outputcolor.r = textureColor.r + textureColor2.r - 0.5;
     outputcolor.g = textureColor.g + textureColor2.g - 0.5;
     outputcolor.b = textureColor.b + textureColor2.b - 0.5;
     outputcolor.a = 1.0;
     outputcolor.r += 0.065 * (1.0 - (2.0 * outputcolor.r - 1.0)*(2.0 * outputcolor.r - 1.0));
     outputcolor.g += 0.065 * (1.0 - (2.0 * outputcolor.g - 1.0)*(2.0 * outputcolor.g - 1.0));
     outputcolor.b += 0.065 * (1.0 - (2.0 * outputcolor.b - 1.0)*(2.0 * outputcolor.b - 1.0));
     gl_FragColor = outputcolor;
 }
);
#endif

@implementation GPUImageOverlayAndWhiterFilter

//@synthesize mix = _mix;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageOverlayAndWhiterFragmentShaderString]))
    {
		return nil;
    }
    
//    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
//    self.mix = 0.5;
    
    return self;
}


#pragma mark -
#pragma mark Accessors

//- (void)setMix:(CGFloat)newValue;
//{
//    _mix = newValue;
//    
//    [self setFloat:_mix forUniform:mixUniform program:filterProgram];
//    printf("mixUniform:%d \n", mixUniform);
//}


@end
