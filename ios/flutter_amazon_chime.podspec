#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_amazon_chime.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_amazon_chime'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for the Amazon Chime SDK, providing audio/video conferencing on iOS and Android.'
  s.description      = <<-DESC
Flutter plugin wrapping the Amazon Chime SDK for real-time audio/video
conferencing, screen sharing, active speaker detection, and data messaging.
                       DESC
  s.homepage         = 'https://github.com/tduongle10/flutter_amazon_chime'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Duong Le' => 'tduongle10@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'AmazonChimeSDK', '~> 0.27.2'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_amazon_chime_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
