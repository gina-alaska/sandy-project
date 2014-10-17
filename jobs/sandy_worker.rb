class SandyWorker
  include Sidekiq::Worker
  class NotImplementedError < Error; end

  def command
    raise NotImplementedError
  end

  def perform id
    # @pass = Job.find(id)
    commands.each do |command|
      cmd = Mixlib::ShellOut.new(command, cwd: workdir)
      #command.run_command
      #command.error!   May not be appropriate. Some tools like to use stderr for info logs

      sleep 10
    end

    # push results to shared storage
    # queue_next_jobs if job.finish!
  end


  def workdir
    @tempdir ||= Tempdir.new
    @tempdir
  end

  def source_datadir
    "/path/to/source/data"
  end
end
