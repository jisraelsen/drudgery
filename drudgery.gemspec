# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'drudgery/version'

Gem::Specification.new do |gem|
  gem.name        = "drudgery"
  gem.version     = Drudgery::VERSION
  gem.authors     = ["Jeremy Israelsen"]
  gem.email       = ["jisraelsen@gmail.com"]
  gem.description = %q{A simple ETL library that supports CSV, SQLite3, and ActiveRecord sources and destinations.}
  gem.summary     = %q{Simple ETL Library}
  gem.homepage    = "http://jisraelsen.github.com/drudgery"

  gem.files         = `git ls-files`.split($/)  
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 1.9.2'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'bundler',             '~> 1.1'
  gem.add_development_dependency 'mocha',               '~> 0.12'
  gem.add_development_dependency 'simplecov',           '~> 0.7'
  gem.add_development_dependency 'coveralls',           '~> 0.6'
  gem.add_development_dependency 'guard-minitest',      '~> 0.5'
  gem.add_development_dependency 'activerecord',        '~> 3.0'
  gem.add_development_dependency 'activerecord-import', '~> 0.2.9'
  gem.add_development_dependency 'sqlite3',             '~> 1.3'
end
