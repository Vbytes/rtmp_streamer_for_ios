


#ifndef __videocore__AdapterSource__
#define __videocore__AdapterSource__

#include <iostream>
#include <videocore/sources/ISource.hpp>
#include <glm/glm.hpp>


#include <map>
#include <thread>
#include <mutex>
#include <glm/glm.hpp>
#include <CoreVideo/CoreVideo.h>
#include <vector>
#include <map>
#include <unordered_map>
namespace videocore { namespace iOS {
    
    /*!
     *  Capture video from the device's cameras.
     */
    class AdapterSource : public ISource,public std::enable_shared_from_this<AdapterSource>
    {
    public:
        
        
        /*! Constructor */
        AdapterSource(int width, int height,OSType pixelFormat,float duration);
        
        /*! Destructor */
        ~AdapterSource();
        
        /*! ISource::setOutput */
        void setOutput(std::shared_ptr<IOutput> output);
        
        /*! 获取原始数据*/
        void PollRawDatas(const char* rawdata,int dataLen);
    
        void start();
        /*! Start the compositor thread */
        void encodeThread();
        
        void setEpoch(const std::chrono::steady_clock::time_point epoch) {
            m_epoch = epoch;
            m_nextEncodeTime = epoch;
        };
    public:
        void sync();
    private:
      std::weak_ptr<IOutput> m_output;
      
        
        
      CVPixelBufferRef      m_pixelBuffer;   //data buffer

      std::chrono::steady_clock::time_point m_epoch;
      std::chrono::steady_clock::time_point m_nextEncodeTime;
      std::chrono::microseconds m_us25;
        
      std::atomic<bool> m_exiting;
      std::atomic<bool> m_mixing;
      std::atomic<bool> m_paused;
        
      std::thread m_CodeThread;
      std::mutex  m_mutex;
      std::condition_variable m_CodeThreadCond;
        
      double m_bufferDuration; //frame duration time
        
      bool              m_shouldSync;
      std::chrono::steady_clock::time_point m_syncPoint;  
    };
}
}
#endif