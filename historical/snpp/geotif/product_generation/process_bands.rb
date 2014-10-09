#!/usr/bin/env ruby
require "trollop"
#############
# Simple command to run several things at once
# ./do_several_at_once.rb -h is your friend/fiend


#wrapper for system - runs command on task
def runner ( command, opts)
  puts("Info: Running: #{command}") if (opts[:verbrose])
  start_time = Time.now
  system(command)
  puts("Info: Done in #{(Time.now - start_time)/60.0}m.") if (opts[:verbrose])
end


## Command line parsing action..
parser = Trollop::Parser.new do
  version "0.0.1 jay@alaska.edu"
  banner <<-EOS
  This util generates a bunch of bands from viirs data using pytroll, the combines them into something useful.  

Usage:
      process_bands.rb [options] --command_to_run <command> <file1> <file2> ....
where [options] is:
EOS

  opt :threads, "The number to run at once, defaults to 2", :default =>  2
  opt :verbrose, "Maxium Verbrosity.", :short => "V"
  opt :dry_run, "Don't actually run the command(s)"
  opt :area, "Area to be used", :default => "alaska"
end


bands = ["M02","M03", "M04", "M05", "M06", "M07", "M08", "M15", "I01", "I02","I03", "I04", "I05", "DNB" ]


opts = Trollop::with_standard_exception_handling(parser) do
  o = parser.parse ARGV
  raise Trollop::HelpNeeded if ARGV.length == 0 # show help screen
  #check for strange threads values
  if(o[:threads]<=0 )
    puts("Error: Number of threads must be greater than 0\n\n\n\n\n\n")
   raise Trollop::HelpNeeded
  end
  o
end


command_template= File.dirname(__FILE__) + "/process_viirs_to_area_single_bands.py -a %s -b %s %s %s" 


#Now, do actual work..
threads = []
1.upto(opts[:threads].to_i) do
        threads << Thread.new do
                loop do
                        todo = bands.pop
                        break if (todo == nil)
                        area = opts[:area]
                        area += "_small"  if ( todo[0] == "M" or todo == "DNB" )
                        command = sprintf(command_template, area, todo, ARGV[0], ARGV[1])
                        puts("Info: Running #{command}")
                        runner(command, opts) if (!opts[:dry_run])
                end
        end
end

threads.each {|t| t.join}


make_virs_script = File.dirname(__FILE__) + "/make_pan_viirs.rb"
make_dnb_viirs_script = File.dirname(__FILE__) + "/make_dnb_viirs.rb"
make_single_band_script = File.dirname(__FILE__) + "/make_single_viirs.rb"

#Now, make some nice products.

#I3, I2, I1 Natural Color (Land Cover)
runner("#{make_virs_script} -V -r I03 -g I02 -b I01 #{ARGV[1]}", opts)
#M5, M4, M3, pan I01
runner("#{make_virs_script} -n -p I01 #{ARGV[1]}", opts)

#M5, M4, M2, pan I01
runner("#{make_virs_script} -V -r M05 -g M04 -b M02 -p I01 #{ARGV[1]}", opts)


#DNB
runner("#{make_dnb_viirs_script} #{ARGV[1]}", opts)
#I05
runner("#{make_single_band_script} -b I05  #{ARGV[1]}", opts)

