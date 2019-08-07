Pod::Spec.new do |spec|

 
  spec.name         = "LuoshiqingNT"

  spec.version      = "0.0.2"

  spec.summary      = "我的网络 LuoshiqingNT."

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author       = { "罗石清" => "644402920@qq.com" }

  spec.platform     = :ios, "9.0"

  spec.homepage     = "https://github.com/luoshiqing/LuoshiqingNT"

  spec.source       = { :git => "https://github.com/luoshiqing/LuoshiqingNT.git", :tag => "#{spec.version}" }

  spec.requires_arc = true
  
  spec.swift_versions = "5.0"

  spec.source_files  = "LuoshiqingNT/**/*.{swift}"


end