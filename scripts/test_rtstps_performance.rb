#!/usr/bin/env ruby

require 'json'

input_dir = ARGV[0]
timedata = []

Dir.glob(File.join(ARGV[0],"*.zero")).each do |raw_file|
  puts "Starting work on #{raw_file}"
  command = "/opt/rt-stps/bin/batch.sh /opt/rt-stps/config/npp.xml #{raw_file}"
  puts command
  start = Time.now.utc
  system(command)
  stop = Time.now.utc
  puts "Finished #{raw_file}"
  duration = stop - start

  timedata.push ({
    file: File.basename(raw_file),
    duration: duration,
    file_size: (File.stat(raw_file).size / (1024 * 1024)),
  })
end

File.open("#{Time.now.strftime("%Y%m%d-%H%M%S")}-rtstps.json", "w") do |f|
  f << JSON.pretty_generate(timedata)
end
