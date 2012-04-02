module Drudgery
  class Manager
    def initialize
      @jobs = []
    end

    def prepare(job=Drudgery::Job.new)
      yield job if block_given?

      @jobs << job
    end

    def run
      @jobs.each { |job| job.perform }
    end
  end
end
