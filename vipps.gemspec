# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "vipps/version"

Gem::Specification.new do |s|
  s.name        = "vipps"
  s.version     = Vipps::VERSION
  s.authors     = ["Andrei Karabitski"]
  s.email       = ["andre@food.farm"]
  s.homepage    = "https://github.com/karabitki/vipps"
  s.summary     = %q{A gem for speaking to Vipps recurring payment service}
  s.description = %q{This gem simplifies the comunication with the vipps service significantly. Right now it only supports register and sale, more is to come.}
  s.has_rdoc    = true

  s.rubyforge_project = "vipps"

  s.add_dependency "httpi"
  s.add_dependency "nori"
  s.add_dependency "hashie"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
