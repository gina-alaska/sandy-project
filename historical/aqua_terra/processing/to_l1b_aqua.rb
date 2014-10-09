#!/bin/env  ruby

ARGV.each do |x|

	system("modis_L1A.py --startnudge=0 --stopnudge=0 #{x}")
	LACs = Dir.glob("*L1A_LAC")
	if (LACs.length != 1 )
		raise ("Found more than one L1A_LAC file - #{LACs.join(" ")} ")
	end
	basename = File.basename(LACs.first, "L1A_LAC")
	case ( basename[0])
                when "T" then 
			system("modis_GEO.py --verbose -d --threshold=95 #{basename}L1A_LAC")
                when "A" then 
			system("/opt/modis_processing/gbad/SPA/gbad/wrapper/gbad/run aqua.gbad.pds P1540957*001.PDS aqua.gbad_eph aqua_eph aqua.gbad_att aqua_att")
			system("modis_GEO.py -a aqua_att -e aqua_eph --verbose -d --threshold=95 #{basename}L1A_LAC")
	end
	system("modis_L1B.py #{basename}L1A_LAC  #{basename}GEO")

	#check and rename
	#T2011034190833.GEO  to 20120105.1259.a1.geo.hdf
	#01234567890123
	t = Time.gm(2000+basename[3,2].to_i) + 24.0*60.0*60.0*(basename[5,3].to_i-1) + 60.0*60.0*basename[8,2].to_i+60.0*basename[10,2].to_i+ basename[12,2].to_i
	new_base = t.strftime("%Y%m%d.%H%M")

	["GEO", "L1B_LAC"].each do |i|
		raise ("Could not find #{basename}#{i}") if ( !File.exists?(basename + i))
	end

	#rename	To Kevin's scheme
	system("ln", basename + "GEO", new_base + ".geo.hdf")
	system("ln", basename+ "L1B_LAC", new_base + ".cal1000.hdf")

        #make links to the nasa style names..
        #system("ln", basename + "GEO", new_base + ".geo.hdf")
        system("ln", basename+ "L1B_LAC", "MOD021KM."+new_base + ".cal1000.hdf")

	case ( basename[0])
		when "T" then  new_base =  "t1." + new_base
		when "A" then new_base = "a1." + new_base
	end

	#rename to Jay's scheme.
        system("ln", basename + "GEO", new_base + ".geo.hdf")
        system("ln", basename+ "L1B_LAC", new_base + ".cal1000.hdf")

	#Make daytime links..
        if ( File.exists?( basename+ "L1B_HKM"))
                system("ln", basename+ "L1B_HKM", new_base + ".cal500.hdf")
                system("ln", basename+ "L1B_QKM", new_base + ".cal250.hdf")
                system("ln", basename+ "L1B_HKM", "MOD02HKM."+new_base + ".cal500.hdf")
                system("ln", basename+ "L1B_QKM", "MOD02QKM."+new_base + ".cal250.hdf")
                system("ln", basename+ "L1B_HKM", new_base + ".cal500.hdf")
                system("ln", basename+ "L1B_QKM", new_base + ".cal250.hdf")
        end


end
