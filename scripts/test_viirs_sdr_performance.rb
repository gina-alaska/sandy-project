#!/usr/bin/env ruby

require 'json'

input_dir = ARGV[0]
timedata = []

Dir.glob(File.join(ARGV[0],"RNSCA-RVIRS*.h5")).each do |raw_file|
  puts "Starting work on #{raw_file}"
  command = "viirs_sdr.sh -W . -z -p 8 -l #{raw_file}"
  puts command
  Dir.mkdir File.basename(raw_file)
  Dir.chdir File.basename(raw_file) do
    start = Time.now.utc
    system(command)
    stop = Time.now.utc
    puts "Finished #{raw_file}"

    duration = stop - start

    timedata.push({
      file: File.basename(raw_file),
      duration: duration,
      file_size: (File.stat(raw_file).size / (1024 * 1024))
    })
  end
end

File.open("#{Time.now.strftime("%Y%m%d-%H%M%S")}-viirs_sdr.json", "w") do |f|
  f << JSON.pretty_generate(timedata)
end
