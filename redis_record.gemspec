# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redis_record/version"

Gem::Specification.new do |s|
  s.name        = "redis_record"
  s.version     = RedisRecord::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Wade Tandy"]
  s.email       = ["wade@wadetandy.com"]
  s.homepage    = "http://github.com/wadetandy/RedisRecord"
  s.summary     = "Ruby object storage system built on Redis"
  s.description = "Ruby object storage system built on Redis"

  s.rubyforge_project = "redis_record"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Dependencies
  s.add_dependency "redis"
  s.add_dependency "active_support"
  s.add_dependency "active_model"
end
