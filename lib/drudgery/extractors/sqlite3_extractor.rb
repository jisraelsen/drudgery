module Drudgery
  module Extractors
    class SQLite3Extractor
      def initialize(db, table)
        @db = db
        @db.results_as_hash = true
        @db.type_translation = true

        @table = table
        @clauses = {}
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
        @db.execute(sql) do |row|
          row.reject! { |key, value| key.kind_of?(Integer) }
          yield row
        end
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
    end
  end
end
