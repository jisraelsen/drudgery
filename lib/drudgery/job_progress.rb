module Drudgery
  class JobProgress < ProgressBar
    def initialize(job_id, total)
      title = "## JOB #{job_id}"

      super(title, total)

      @title_width = title.length + 1
    end
  end
end
