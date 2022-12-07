[English](./README.md) | 简体中文

# 即时通信 IM
## 产品简介
即时通信 IM（Instant Messaging）基于 QQ 底层 IM 能力开发，仅需植入 IM SDK 即可轻松集成聊天、会话、群组、资料管理和直播弹幕能力，也支持通过信令消息与白板等其他产品打通，全面覆盖您的业务场景，支持各大平台小程序接入使用，全面满足通信需要。

<table style="text-align:center; vertical-align:middle; width:200px">
  <tr>
    <th style="text-align:center;" width="200px">iOS 体验 App</th>
  </tr>
  <tr>
    <td><img style="width:200px" src="https://qcloudimg.tencent-cloud.cn/raw/b1ea5318e1cfce38e4ef6249de7a4106.png"/></td>
</table>

我们提供了一套基于 IM SDK 的 TUIKit 组件库，组件库包含了会话、聊天、搜索、关系链、群组、音视频通话等功能。基于 UI 组件您可以像搭积木一样快速搭建起自己的业务逻辑。

<img src="https://qcloudimg.tencent-cloud.cn/raw/9c893f1a9c6368c82d44586907d5293d.png" style="zoom:50%;"/>

## 跑通 Demo
本文介绍如何快速跑通 iOS 平台即时通信 IM 的体验 Demo。
对于其他平台，请参考文档：

[**chat-uikit-android**](https://github.com/TencentCloud/chat-uikit-android)

[**chat-uikit-flutter**](https://github.com/TencentCloud/chat-uikit-flutter)

[**chat-uikit-vue**](https://github.com/TencentCloud/chat-uikit-vue)

[**chat-uikit-react**](https://github.com/TencentCloud/chat-uikit-react)

[**chat-uikit-uniapp**](https://github.com/TencentCloud/chat-uikit-uniapp)

[**chat-uikit-wechat**](https://github.com/TencentCloud/chat-uikit-wechat)


## 步骤1：创建应用
1. 登录即时通信 IM [控制台](https://console.cloud.tencent.com/avc)。
> 如果您已有应用，请记录其 SDKAppID 并 [配置应用](#step2)。
2. 在【应用列表】页，单击【创建应用接入】。
3. 在【创建新应用】对话框中，填写新建应用的信息，单击【确认】。
应用创建完成后，自动生成一个应用标识 SDKAppID，请记录 SDKAppID 信息。

## 步骤2：获取密钥信息

1. 单击目标应用所在行的【应用配置】，进入应用详情页面。
3. 单击**帐号体系集成**右侧的【编辑】，配置**帐号管理员**信息，单击【保存】。
![](https://main.qcloudimg.com/raw/2ad153a77fe6f838633d23a0c6a4dde1.png)
4. 单击【查看密钥】，拷贝并保存密钥信息。
> 请妥善保管密钥信息，谨防泄露。

## 步骤3：下载并配置 Demo 源码

1. 从 [Github](https://github.com/TencentCloud/chat-uikit-ios) 克隆即时通信 IM Demo 工程。
2. 打开所属终端目录的工程，找到对应的`GenerateTestUserSig`文件。
<table>
<tr>
<th nowrap="nowrap">所属平台</th>  
<th nowrap="nowrap">文件相对路径</th>  
</tr>
<tr>      
<td>Android</td>   
<td>Android/Demo/app/src/main/java/com/tencent/qcloud/tim/demo/signature/GenerateTestUserSig.java</td>   
</tr> 
<tr>
<td>iOS</td>   
<td>iOS/Demo/TUIKitDemo/Private/GenerateTestUserSig.h</td>
</tr> 
</table>


3. 设置`GenerateTestUserSig`文件中的相关参数：


- SDKAPPID：请设置为 [步骤1](#step1) 中获取的实际应用 SDKAppID。
- SECRETKEY：请设置为 [步骤2](#step2) 中获取的实际密钥信息。
![](https://main.qcloudimg.com/raw/bfbe25b15b7aa1cc34be76d7388562aa.png)


> !本文提到的获取 UserSig 的方案是在客户端代码中配置 SECRETKEY，该方法中 SECRETKEY 很容易被反编译逆向破解，一旦您的密钥泄露，攻击者就可以盗用您的腾讯云流量，因此**该方法仅适合本地跑通 Demo 和功能调试**。
>正确的 UserSig 签发方式是将 UserSig 的计算代码集成到您的服务端，并提供面向 App 的接口，在需要 UserSig 时由您的 App 向业务服务器发起请求获取动态 UserSig。更多详情请参见 [服务端生成 UserSig](https://cloud.tencent.com/document/product/269/32688#GeneratingdynamicUserSig)。

## 步骤4：编译运行（全部功能）
1. 终端执行以下命令，检查 pod 版本。
```objectivec
pod --version
```
如果提示 pod 不存在，或者 pod 版本小于 1.7.5，请执行以下命令安装最新 pod。
```
// 更换源
gem sources --remove https://rubygems.org/
gem sources --add https://gems.ruby-china.com/
// 安装 pod
sudo gem install cocoapods -n /usr/local/bin
// 如果安装了多个 Xcode ，请使用下面的命令选择 Xcode 版本（一般选择最新的 Xcode 版本）
sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
// 更新 pod 本地库
pod setup
```
2. 终端执行以下命令，加载 ImSDK 库。
```
cd iOS/Demo
pod install
```
3. 如果安装失败，运行以下命令更新本地的 CocoaPods 仓库列表
```
pod repo update
```
4. 进入 iOS/Demo 文件夹，打开 `TUIKitDemo.xcworkspace` 编译运行。

> **注意：Demo 默认集成了音视频通话组件，由于音视频通话组件依赖的音视频 SDK 暂不支持模拟器，请使用真机调试/运行 Demo**

## 步骤5：编译运行（移除音视频通话功能）
如果您不想集成音视频通话功能，可以按照下面的步骤移除:
1. 进入 iOS/Demo 文件夹，修改 `Podfile` 文件，屏蔽 `TUICallKit pod  集成，然后执行 `pod install` 命令。
```
#  pod 'TUICallKit' （不需要再集成该库）
```

操作完后会发现，Demo 中的音频通话、视频通话入口均被隐藏。

会话界面屏蔽 TUICallKit 前后的效果：

| before | After |
|---------|---------|
|<img width="390" alt="GitHub_ChatIncludeCallMinimalist" src="https://user-images.githubusercontent.com/19159722/205884017-f7ab8c73-a3bf-414a-9801-00ba82b5285b.png">|<img width="390" alt="GitHub_ChatExcludeCallMinimalist" src="https://user-images.githubusercontent.com/19159722/205884361-582e40fe-9232-479e-9924-39732841dfa1.png">


联系人资料界面屏蔽 TUICallKit 前后的效果：
| before | After |
|---------|---------|
|<img width="390" alt="GitHub_ContactIncludeCallMinimalist" src="https://user-images.githubusercontent.com/19159722/205884529-29b75f55-fddb-449f-aa4a-1444503901d0.png"> |<img width="390" alt="GitHub_ContactExcludeCallMinimalist" src="https://user-images.githubusercontent.com/19159722/205884777-3adc36da-a1c6-4e18-b3e9-d425e050aa49.png">

> 以上演示的仅仅是 Demo 对移除音视频通话功能的处理，开发者可以按照业务要求自定义。


## 步骤6：编译运行（移除搜索功能）
进入 iOS/Demo 文件夹，修改 `Podfile` 文件，屏蔽 `TUISearch` pod  集成，然后执行 `pod install` 命令。
```
#  pod 'TUISearch' （不需要再集成该库）
```

操作完后会发现，Demo 中的消息搜索框被隐藏。

消息界面屏蔽 TUISearch 前后的效果：

| before | After |
|---------|---------|
| <img width="390" alt="GitHub_ConversationIncludeSearchMinimalist" src="https://user-images.githubusercontent.com/19159722/205884953-20496c4d-33d2-48b4-92c4-9c8a108ba489.png"> | <img width="390" alt="GitHub_ConversationExcludeSearchMinimalist" src="https://user-images.githubusercontent.com/19159722/205892412-9c7556bf-a1b6-4eae-b5c2-329b009e3db2.png">

> 以上演示的仅仅是 Demo 对移除搜索功能的处理，开发者可以按照业务要求自定义。
