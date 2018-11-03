# 证书生成脚本文件

------

工程中包含三个证书生成脚本，其中包括使用OpenSSL生成的RSA证书以及使用GmSSL生成的国密证书，国密证书的SHA算法使用天安开源的TaSSL生成，根据不同需求可以修改脚本文件和配置文件内容，生成对应的证书文件。


### Linux

> 下载并安装所需的OpenSSL，直接运行对应的shell脚本。

------

## 脚本文件描述

工程中包含三个shell脚本，分别为RSAcertgen.sh、SM2certgen.sh和gmcert.sh，其中gmcert.sh和RSAcertgen.sh使用openssl.cnf配置文件，SM2certgen.sh使用到全部的配置文件。生成的证书信息在rsaCerts文件夹内，证书名称可以在脚本内自行修改。下面仅对SM2certgen.sh脚本和证书文件夹说明。

### 1. rsaCerts文件夹 
生成两组证书，分别为客户端和服务端使用，证书req_distinguished_name属性使用-subj填充，数据可以根据需求自行修改。

### 2. SM2certgen.sh
此脚本为生成国密双证书VPN使用，用于国标《GM/T 0024-2014》中证书，签发的证书包括加密证书和签名证书，证书扩展属性在对应的.cnf文件中配置，req_distinguished_name也在对应的文件中配置。
