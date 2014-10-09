#!/bin/env  ruby
require "fileutils"

system("update_luts.py aqua -v")

ARGV.each do |x|
	begin
		working_dir = File.basename(x, ".zero.gz")
		next if (File.exists?(working_dir))
		system("mkdir", working_dir)
		FileUtils.cd(working_dir) do 
			system("cp ../#{File.basename(x)} .")
			cmd = ["ruby", File.dirname(__FILE__) + "/to_pds.rb", File.basename(x)]
			puts "running:" + cmd.join(" ")
			system(*cmd)
			pds = Dir.glob("P1540064*001.PDS")
			raise ("too many/not enough pds files => #{pds.join(" ")}") if (pds.length != 1 )
			system(File.dirname(__FILE__) + "/to_l1b_aqua.rb", pds.first)
			cal1000 = Dir.glob("[0-9]*.cal1000.hdf")
			raise ("too many/not enought cal1000 files => #{cal1000.join(" ")}") if (cal1000.length != 1 )
			to_delete =  Dir.glob("*.PDS") +  Dir.glob("*.zero")
			to_delete.each {|fl| system("rm", "-v", fl) }
		end
	rescue RuntimeError => e
		puts("An error occured while processing #{x}")
		system("mkdir problems") if (!File.exists?("problems"))
		system("mv -v #{x} #{File.basename(x, ".zero.gz")} problems/")
	end


end
