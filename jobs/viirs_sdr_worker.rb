require 'sidekiq'

class ViirsSdrWorker < SandyWorker

  def command
    cpu_count = 8
    [ "viirs_sdr.sh -l -z -p #{cpu_count} #{source_data_path}",
      "run_viirs_crefl.sh" ]
  end
end
