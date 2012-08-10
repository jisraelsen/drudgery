# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'drudgery/version'

Gem::Specification.new do |s|
  s.name        = 'drudgery'
  s.version     = Drudgery::VERSION
  s.authors     = ['Jeremy Israelsen']
  s.email       = ['jisraelsen@gmail.com']
  s.homepage    = 'http://jisraelsen.github.com/drudgery'
  s.summary     = 'Simple ETL Library'
  s.description = 'A simple ETL library that supports CSV, SQLite3, and ActiveRecord sources and destinations.'

  s.required_ruby_version = '>= 1.9.2'

  s.rubyforge_project = 'drudgery'

  s.files         = `git ls-files -- lib/*`.split("\n") + %w[LICENSE README.md]
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_path  = 'lib'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'bundler',             '~> 1.1'
  s.add_development_dependency 'mocha',               '~> 0.12'
  s.add_development_dependency 'simplecov',           '~> 0.6'
  s.add_development_dependency 'guard-minitest',      '~> 0.5'
  s.add_development_dependency 'activerecord',        '~> 3.0'
  s.add_development_dependency 'activerecord-import', '~> 0.2.9'
  s.add_development_dependency 'sqlite3',             '~> 1.3'
end
