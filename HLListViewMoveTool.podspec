Pod::Spec.new do |s|
s.name = 'HLListViewMoveTool'
s.version = '1.0.1'
s.license = 'MIT'
s.summary = 'custom tableViewCell and collectionViewCell move tool in iOS.'
s.homepage = 'https://github.com/alin94/HLListViewMoveTool'
s.authors = { 'alin' => '946559304@qq.com' }
s.source = { :git => "https://github.com/alin94/HLListViewMoveTool.git", :tag => "1.0.1"}
s.requires_arc = true
s.ios.deployment_target = '8.0'
s.source_files = 'HLListViewMoveTool/*'
s.frameworks = 'Foundation', 'UIKit'

end
