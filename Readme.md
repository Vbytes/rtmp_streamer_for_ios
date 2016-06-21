# IOS推流SDK
###   环境配置：
		1. 安装CocoaPods,pod 版本为0.38.2 过高或过低可能导致编译失败
		   具体参考 https://ruby.taobao.org/
		2. 配置xcode 环境，Build Location 设置为Custom ->Relative to workspace
		   具体参考 https://developer.apple.com/library/ios/recipes/xcode_help-locations_preferences/Build/Build.html
		3. 以上两个步骤设置错误你将会出现莫名奇妙的错误，good luck!
###   安装步骤：
      1. 进入GPUImage目录,framework 文件夹下 执行pod install --verbose --no-repo-update 命令。
      2. 步骤一执行成功后，会出现GPUImage.xcworkspace 工程，打开进行realesae 版本编译，或者执行 同级的build.sh文件
          build.sh 脚本会命令行式编译，最终将会生成步骤三中的文件
      3. 不出意外的话将会生成IOSStreamer.framework在IOSStreamers/build目录下
      4. 将生成的framework 拖动到test 工程下进行测试。
###   主要功能：
     1. 编码方式：ios8.0以上版本H264,AAC 硬件编码
     2. 码率： 智能码率调整算法，根据网络状况自动调节码率。
     3. 滤镜： 实时性超强的美白，磨皮功能
     4. 加速： gpu加速，渲染
     5. 稳定性： 系统自动断线重传，低cpu,低内存。
     6. 辅助功能：支持语音，视频混合。
     7. 图像质量：支持720p一下格式
     8. 摄像头： 支持前后摄像头实时切换
     9. 低延时： 在rtmp-nginx + srs播放器网络状况良好情况下1秒延时，网络状况差时延时能自动缩小到3秒内。
     10. 丢包策略： 当发送队列超过阈值时，自动丢掉gop,防止出现马赛克。
     11. 实时监控： 能够实时监控推流端buffer,丢包，以及码率情况。
###   效果图：
     
     
      	
