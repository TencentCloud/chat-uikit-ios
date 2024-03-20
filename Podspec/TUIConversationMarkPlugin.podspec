Pod::Spec.new do |spec|
    spec.name         = 'TUIConversationMarkPlugin'
    spec.version      = '7.8.5483'
    spec.platform     = :ios 
    spec.ios.deployment_target = '10.0'
    spec.license      = { :type => 'Proprietary',
        :text => <<-LICENSE
          copyright 2017 tencent Ltd. All rights reserved.
          LICENSE
         }
    spec.homepage     = 'https://cloud.tencent.com/document/product/269/3794'
    spec.documentation_url = 'https://cloud.tencent.com/document/product/269/9147'
    spec.authors      = 'tencent video cloud'
    spec.summary      = 'TUIConversationMarkPlugin'
    
    spec.requires_arc = true
  
    spec.source = { :http => 'https://im.sdk.cloud.tencent.cn/download/tuiplugin/7.8.5483/ios/TUIConversationMarkPlugin_7.8.5483.framework.zip'}
    spec.preserve_paths = 'TUIConversationMarkPlugin.framework'
    spec.vendored_frameworks = 'TUIConversationMarkPlugin.framework'
    spec.pod_target_xcconfig = {
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    spec.user_target_xcconfig = { 
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    } 
  end

# pod trunk push TUIConversationMarkPlugin.podspec --use-libraries --allow-warnings