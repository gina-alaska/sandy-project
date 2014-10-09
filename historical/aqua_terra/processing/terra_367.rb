#!/bin/env  ruby
require "fileutils"
prm_files="$HOME/scripts/nps367/"

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
			pds = Dir.glob("*001.PDS")
			raise ("too many/not enough pds files => #{pds.join(" ")}") if (pds.length != 1 )
			system(File.dirname(__FILE__) + "/to_l1b.rb", pds.first)
			cal1000 = Dir.glob("*.cal1000.hdf")
			raise ("too many/not enought cal1000 files => #{cal1000.join(" ")}") if (cal1000.length != 1 )
			basename = File.basename(cal1000.first,".cal1000.hdf") 
			cmd = "$HOME/scripts/nps367/hdf_to_367tif_shift.bash #{basename}.cal250.hdf #{basename}.cal500.hdf #{basename}.geo.hdf " + 
				" #{prm_files}/alaska_albers_nps_250m_proj_367_final.prm #{prm_files}/alaska_albers_nps_500m_proj_367_final.prm ."
			system(cmd)

			Dir.glob("*").each {|fl| system("rm", "-v", fl) if (!fl.include?("367_stretch.tif"))}
			raise ("Didn't generate final tiff.") if (Dir.glob("*367_stretch.tif").length != 1 )
		
		end
	rescue RuntimeError => e
		puts("An error occured while processing #{x}")
		system("mkdir problems") if (!File.exists?("problems"))
		system("mv -v #{x} #{File.basename(x, ".zero.gz")} problems/")
	end
end
