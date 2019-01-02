# 简单描述

------

程序使用OpenSSL测试国密双证书功能，包含客户端和服务端使用的OpenSSL接口，其中_engine为调用OpenSSL的engine机制实现硬件扩展，国密SKF接口硬件测试demo，目前基于GmSSL的国密SFK硬件测试功能已经完成，测试正常，使用只需要将当前的SKF.so文件配置到安装OpenSSL的lib库下engines-1.1目录。

###  功能列表
- [x] 双向认证
- [ ] 阻塞模式
- [x] ENGINE方式
- [x] 国密双证书
- [ ] 多平台支持


### [Windows/Mac/Linux 全平台客户端]

> 代码在多平台共用，整理完成后上传。
