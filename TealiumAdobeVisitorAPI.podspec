Pod::Spec.new do |s|

    # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.name         = "TealiumAdobeVisitorAPI"
    s.module_name  = "TealiumAdobeVisitorAPI"
    s.version      = "1.2.0"
    s.summary      = "Tealium Swift Adobe Visitor API integration"
    s.description  = <<-DESC
    Tealium Swift Adobe Visitor API integration.
    DESC
    s.homepage     = "https://github.com/Tealium/tealium-ios-adobe-visitor-api"

    # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.license      = { :type => "Commercial", :file => "LICENSE.txt" }
    
    # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.authors            = { "Tealium Inc." => "tealium@tealium.com",
        "craigrouse"   => "craig.rouse@tealium.com" }
    s.social_media_url   = "https://twitter.com/tealium"

    # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.swift_version = "5.0"
    s.ios.deployment_target = "12.0" 
    s.osx.deployment_target = "10.14"
    s.watchos.deployment_target = "4.0"
    s.tvos.deployment_target = "12.0"

    # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source       = { :git => "https://github.com/Tealium/tealium-ios-adobe-visitor-api.git", :tag => "#{s.version}" }
    # s.source = { :git => "https://github.com/Tealium/tealium-ios-adobe-visitor-api.git", :branch => "main"}

    # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source_files      = "TealiumAdobeVisitorAPI/*.{swift}"

    # ――― Dependencies ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.dependency 'tealium-swift/Core', '~> 2.12'

end

