module Drudgery
  module Extractors
    class SQLite3Extractor
      attr_reader :name

      def initialize(db, table)
        @db = db
        @db.results_as_hash = true
        @db.type_translation = true

        @table = table
        @clauses = {}

        @name = "sqlite3:#{main_db_name}.#{@table}"
      end

      def select(*expressions)
        @clauses[:select] = expressions.join(', ')
      end

      def from(expression)
        @clauses[:from] = expression
      end

      def joins(*clauses)
        @clauses[:joins] = clauses
      end

      def where(condition)
        @clauses[:where] = condition
      end

      def group(*expressions)
        @clauses[:group] = expressions.join(', ')
      end

      def having(condition)
        @clauses[:having] = condition
      end

      def order(*expressions)
        @clauses[:order] = expressions.join(', ')
      end

      def extract
        index = 0

        @db.execute(sql) do |row|
          row.reject! { |key, value| key.kind_of?(Integer) }
          yield [row, index]

          index += 1
        end
      end

      def record_count
        @record_count ||= @db.get_first_value(count_sql)
      end

      private
      def sql
        clauses = [
          "SELECT #{@clauses[:select] || '*'}",
          "FROM #{@clauses[:from] || @table}"
        ]

        (@clauses[:joins] || []).each do |join|
          clauses << join
        end

        clauses << "WHERE #{@clauses[:where]}"    if @clauses[:where]
        clauses << "GROUP BY #{@clauses[:group]}" if @clauses[:group]
        clauses << "HAVING #{@clauses[:having]}"  if @clauses[:having]
        clauses << "ORDER BY #{@clauses[:order]}" if @clauses[:order]

        clauses.join(' ')
      end

      def count_sql
        if @clauses.empty?
          "SELECT COUNT(*) FROM #{@table}"
        else
          "SELECT COUNT(*) FROM (#{sql})"
        end
      end

      def main_db_name
        main = @db.database_list.detect { |list| list['name'] == 'main' }

        if main['file'].empty?
          'memory'
        else
          File.basename(main['file']).split('.').first
        end
      end
    end
  end
end
