class ViirsToAwipsWorker < SandyWorker
  def command
    "viirs2gtiff --num-procs=#{cpu_count} -D #{source_data_dir} --grid-configs #{ENV['P2G_GRIDS']}"
  end
end
