#!/usr/bin/env ruby

require 'json'

data = JSON.parse(File.read(ARGV[0]))

new_data = data.map do |file, d|
  {
    file: file,
    duration: d['duration'],
    size: d['file_size']
  }
end

puts JSON.pretty_generate(new_data)
