require 'benchmark'
require 'csv'
require 'progressbar'

require 'drudgery/version'
require 'drudgery/progressbar'
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
    attr_accessor :logger, :show_progress

    def log(mode, message)
      logger.send(mode, message) if logger
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

Drudgery.show_progress = true
