require 'csv'

require 'drudgery/version'
require 'drudgery/manager'
require 'drudgery/job'
require 'drudgery/transformer'

require 'drudgery/extractors/active_record_extractor'
require 'drudgery/extractors/csv_extractor'
require 'drudgery/extractors/sqlite3_extractor'

require 'drudgery/loaders/active_record_import_loader'
require 'drudgery/loaders/active_record_loader'
require 'drudgery/loaders/csv_loader'
require 'drudgery/loaders/sqlite3_loader'

module Drudgery
  class << self
    def listeners
      @listeners ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def subscribe(event, &block)
      listeners[event] << block
    end

    def unsubscribe(event)
      listeners[event].clear
    end

    def notify(event, *args)
      listeners[event].each do |listener|
        listener.call(*args)
      end
    end
  end

  module Extractors
    def self.instantiate(type, *args)
      case type
      when :csv
        extractor = Drudgery::Extractors::CSVExtractor
      when :sqlite3
        extractor = Drudgery::Extractors::SQLite3Extractor
      else
        extractor = Drudgery::Extractors.const_get("#{type.to_s.split('_').map(&:capitalize).join}Extractor")
      end

      extractor.new(*args)
    end
  end

  module Loaders
    def self.instantiate(type, *args)
      case type
      when :csv
        loader = Drudgery::Loaders::CSVLoader
      when :sqlite3
        loader = Drudgery::Loaders::SQLite3Loader
      else
        loader = Drudgery::Loaders.const_get("#{type.to_s.split('_').map(&:capitalize).join}Loader")
      end

      loader.new(*args)
    end
  end
end
