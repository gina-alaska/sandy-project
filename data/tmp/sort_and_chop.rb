#!/usr/bin/env ruby

require 'json'

source = JSON.parse(File.read(ARGV[0]))

source.each do |item|
  item['file'] = item['file'].split("_")[0..3].join("_")
end.sort!{|i,j| i['file'] <=> j['file']}

puts JSON.pretty_generate(source)
