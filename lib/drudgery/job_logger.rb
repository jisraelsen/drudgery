module Drudgery
  class JobLogger
    def initialize(job_id)
      @prefix = "## JOB #{job_id}"
    end

    def log_with_progress(mode, message)
      STDERR.puts format_message(message) if Drudgery.show_progress
      log(mode, message)
    end

    def log(mode, message)
      Drudgery.log mode, format_message(message)
    end

    private
    def format_message(message)
      "#{@prefix}: #{message}"
    end
  end
end
