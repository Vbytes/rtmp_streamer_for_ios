#import "GPUImageSubtractionFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageSubtractionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;

 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 // uniform highp float mixturePercent = 128;

 void main()
 {
	 lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
	 lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);
     
     lowp vec4 outputcolor;
     outputcolor.r = textureColor2.r - textureColor.r + 0.5;
     outputcolor.g = textureColor2.g - textureColor.g + 0.5;
     outputcolor.b = textureColor2.b - textureColor.b + 0.5;
     outputcolor.a = 1.0;
     gl_FragColor = outputcolor;
     
 }
);

#else
NSString *const kGPUImageSubtractionFragmentShaderString = SHADER_STRING
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
     outputcolor.r = textureColor2.r - textureColor.r + 0.5;
     outputcolor.g = textureColor2.g - textureColor.g + 0.5;
     outputcolor.b = textureColor2.b - textureColor.b + 0.5;
     outputcolor.a = 1.0;
     gl_FragColor = outputcolor;
 }
);
#endif

@implementation GPUImageSubtractionFilter

//@synthesize mix = _mix;

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSubtractionFragmentShaderString]))
    {
		return nil;
    }
    
//    mixUniform = [filterProgram uniformIndex:@"mixturePercent"];
//    self.mix = 0.5;
    
    return self;
}


#pragma mark -
#pragma mark Accessors


@end
