#!/bin/env  ruby

ARGV.each do |x|

	basename = File.basename(x, "L1A_LAC")
	system("modis_GEO.py --threshold 95 #{basename}L1A_LAC")
	system("modis_L1B.py #{basename}L1A_LAC  #{basename}GEO")

	#check and rename
	#T2011034190833.GEO  to 20120105.1259.a1.geo.hdf
	#01234567890123
	t = Time.gm(2000+basename[3,2].to_i) + 24.0*60.0*60.0*basename[5,3].to_i + 60.0*60.0*basename[8,2].to_i+60.0*basename[10,2].to_i+ basename[12,2].to_i
	new_base = t.strftime("%Y%m%d.%H%M")

	["GEO", "L1B_LAC","L1B_HKM","L1B_QKM"].each do |i|
		raise ("Could not find #{basename}#{i}") if ( !File.exists?(basename + i))
	end

	#rename	
	system("mv", basename + "GEO", new_base + ".geo.hdf")
	system("mv", basename+ "L1B_LAC", new_base + ".cal1000.hdf")
	system("mv", basename+ "L1B_HKM", new_base + ".cal500.hdf")
	system("mv", basename+ "L1B_QKM", new_base + ".cal250.hdf")
"L1B_LAC"
	

end
