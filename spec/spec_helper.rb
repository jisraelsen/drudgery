if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'minitest/spec'
require 'minitest/autorun'
require 'mocha'

require 'drudgery'
