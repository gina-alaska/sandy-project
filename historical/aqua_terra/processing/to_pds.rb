#!/bin/env  ruby

ARGV.each do |x|
	case (x.split(".").last)
		when "gz"
			system("gunzip", x)
			x = File.basename(x, ".gz")
		when "bz2"
			system("bunzip2", x)
                	x = File.basename(x, ".bz2")
		when "zero"
			#do nothing
			x = File.basename(x)
	end

	case (x.split(".").first)
		when "t1"
			system("$MODIS/rt-stps/bin/batch.sh $MODIS/rt-stps/config/terra.xml ./#{x}")
		when "a1"
			system("$MODIS/rt-stps/bin/batch.sh $MODIS/rt-stps/config/aqua.xml ./#{x}")
	end
end
