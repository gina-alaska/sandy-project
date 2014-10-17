class ViirsToAwipsWorker < SandyWorker
  def command
    "viirs2awips --num-procs=#{cpu_count} -D #{source_data_dir}"
  end
end
