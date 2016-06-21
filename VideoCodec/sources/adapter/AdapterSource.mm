#include "videocore/sources/adapter/AdapterSource.h"
#include <videocore/mixers/IVideoMixer.hpp>
#include <videocore/system/pixelBuffer/Apple/PixelBuffer.h>



namespace videocore { namespace iOS {
    AdapterSource::AdapterSource(int width, int height,OSType pixelFormat,float duration)
    :
    m_epoch(std::chrono::steady_clock::now()),
    m_exiting(false),
    m_bufferDuration(duration)
    {
        CVPixelBufferRef pb = nullptr;
        CVReturn ret = kCVReturnSuccess;
        @autoreleasepool {
            NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                                  (NSString*) kCVPixelBufferWidthKey : @(width),
                                                  (NSString*) kCVPixelBufferHeightKey : @(height),
                                                  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
                                                  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
            
            ret = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormat, (__bridge CFDictionaryRef)pixelBufferOptions, &pb);
        }
        if(!ret) {
            m_pixelBuffer = pb;
        } else {
            throw std::runtime_error("PixelBuffer creation failed");
        }
    }
    
    AdapterSource::~AdapterSource()
    {
        m_exiting = true;
        m_CodeThreadCond.notify_all();
    }
    void
    AdapterSource::setOutput(std::shared_ptr<IOutput> output)
    {
        m_output = output;
      
        
    }
    void
    AdapterSource::start() {
        m_CodeThread = std::thread([this](){ this->encodeThread(); });
    }
    void AdapterSource::encodeThread()
    {
        const auto us = std::chrono::microseconds(static_cast<long long>(m_bufferDuration * 1000000.));
        const auto us_25 = std::chrono::microseconds(static_cast<long long>(m_bufferDuration * 250000.));
        m_us25 = us_25;
        pthread_setname_np("com.videocore.encodeloop");
        
        m_nextEncodeTime = m_epoch;
        
        
        while(!m_exiting.load())
        {
            std::unique_lock<std::mutex> l(m_mutex);
            const auto now = std::chrono::steady_clock::now();
            if(now >= m_nextEncodeTime) {
                
                auto currentTime = m_nextEncodeTime;
                if(!m_shouldSync) {
                    m_nextEncodeTime += us;
                } else {
                    m_nextEncodeTime = m_syncPoint > m_nextEncodeTime ? m_syncPoint + us : m_nextEncodeTime + us;
                }
                
                auto lout = this->m_output.lock();
                if(lout) {
 
                    MetaData<'vide'> md(std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - m_epoch).count());
                    lout->pushBuffer((uint8_t*)this->m_pixelBuffer, sizeof(this->m_pixelBuffer), md);
                    
                }
                
                m_CodeThreadCond.wait_until(l, m_nextEncodeTime);
                
            }//end if(now >= (m_nextMixTime))
            
            
            
            
        }
        
    }

    void AdapterSource::PollRawDatas(const char* rawdata,int dataLen)
    {
        
 
        CVPixelBufferLockBaseAddress((CVPixelBufferRef)m_pixelBuffer, 0);
        char* loc = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)m_pixelBuffer);
        memcpy(loc, rawdata, dataLen);
        CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)m_pixelBuffer, 0);
 
    }
    void
    AdapterSource::sync() {
        m_syncPoint = std::chrono::steady_clock::now();
        m_shouldSync = true;

    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
}
