#!/usr/bin/env ruby

command = "viirs_sdr.sh -W #{workdir} -z -p 8 -l #{source_file}"

start = Time.now.utc
system(command)
stop = Time.now.utc

duration = stop - start

File.open("", "w") do |f|
  f << JSON.pretty_generate({
    file: source_file,
    size: (File.stat(source_file).size / (1024 * 1024)),
    duration: duration
  })
end
