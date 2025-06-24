Pod::Spec.new do |s|
  s.name         = 'JanusSDK'
  s.version      = '1.0.16'
  s.summary      = 'Janus SDK for iOS applications'
  s.description  = 'Janus SDK provides privacy consent management for iOS applications.'
  s.homepage     = 'https://github.com/ethyca/janus-sdk-ios'
  s.license      = { :type => 'Commercial', :text => 'See https://github.com/ethyca/janus-sdk-ios/blob/main/LICENSE' }
  s.author       = { 'Ethyca' => 'info@ethyca.com' }
  s.source       = { :http => "https://raw.githubusercontent.com/ethyca/janus-sdk-ios/#{s.version}/JanusSDK.xcframework.zip" }
  s.ios.deployment_target = '13.0'
  s.vendored_frameworks = 'JanusSDK.xcframework'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'PRODUCT_BUNDLE_IDENTIFIER' => 'com.ethyca.janussdk.ios' }
end 