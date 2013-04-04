require 'simplecov'
require 'coveralls'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter '/spec/'
end

require 'minitest/spec'
require 'minitest/autorun'
require 'mocha'

require 'drudgery'

require 'sqlite3'
require 'active_record'
require 'activerecord-import'
