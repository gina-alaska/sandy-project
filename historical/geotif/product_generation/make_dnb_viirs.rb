#!/usr/bin/env ruby
require "trollop"
require "fileutils"
#############
# Simple command to run several things at once
# ./make_pan_viirs.rb -h is your friend/fiend


#wrapper for system - runs command on task
def runner ( command, opts)
  puts("Info: Running: #{command}") if (opts[:verbrose])
  start_time = Time.now
  system(command)
  puts("Info: Done in #{(Time.now - start_time)/60.0}m.") if (opts[:verbrose])
end

def get_band (color )
  puts ("Looking for npp*#{color}*_float.tif")
  band = Dir.glob("npp*#{color}*_float.tif")
  raise(RuntimeError, "Too many bands found ({green.join(",")} for band #{color}") if (band.length > 1)
  raise(RuntimeError,"No bands found for band #{color}") if (band.length == 0)
  band.first
end


## Command line parsing action..
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util makes a dnb image from viirs data.   

Usage:
    make_dnb_viirs.rb [options] <viirs dir> 
where [options] is:
EOS
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :dry_run, "Don't actually run the command(s)"
end

opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length != 1 # show help screen
  o
end

#contrast_options = "-ndv 0 -linear-stretch 100 60  -outndv 0 "
contrast_options = " -ndv 0 -percentile-range .02 .98  -outndv 0 "
gdal_opts = "-co TILED=YES -co COMPRESS=LZW -a_nodata \"0 0 0\" "

FileUtils.cd(ARGV[0]) do
  tmp_name = "DNB.tmp"
  dnb = get_band("DNB")
  final_file = File.basename(dnb).split("_").first + "_DNB"
  runner("gdal_contrast_stretch #{contrast_options} #{dnb} #{tmp_name}.tif", opts)
  runner("gdal_translate #{gdal_opts} #{tmp_name}.tif #{final_file}.tif ", opts)
  runner("add_overviews.rb #{final_file}.tif ", opts)
  runner("rm -v  #{tmp_name}.tif", opts)
end
