$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "independize/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "independize"
  s.version     = Independize::VERSION
  s.authors     = ["aikyo02"]
  s.email       = ["aikyo02@gmail.com"]
  s.homepage    = "https://github.com/aikyo02"
  s.summary     = "Generate error pages"
  s.description = "Generate error pages"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'actionview', ">= 4.0"
  s.add_dependency "sprockets"
end
