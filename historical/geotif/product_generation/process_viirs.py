#!/usr/bin/env python2 
import os
import fnmatch
import datetime
import sys
import glob
from mpop.satellites import PolarFactory
from mpop.scene import assemble_segments

#Looks at the filesize of the granule and rejects it if any
# of the files for the given bands are too small, or from 1958
# This should prevent geolocation errors when the
# granules are combined.
def isvalidgranule(granule,bands,path):
  pattern = "SV%(band)s_%(satellite)s_d%Y%m%d_t%H%M???_e???????_b%(orbit)s_c*h5"
  values = { "orbit": granule.orbit,
             "satname": granule.satname,
             "instrument": granule.instrument_name,
             "satellite": granule.satname }
  if(granule.time_slot.strftime("%Y") == "1958"):
    print "Blast from the past"
    return False
  for band in bands:
    values["band"] = band
    filename = granule.time_slot.strftime( pattern ) % values
    files = glob.glob(os.path.join(path,filename))
    for file in files:
      #Reject small files
      print "Looking at " + file
      if(os.path.getsize(file) < 1000000):
        print "Tiny File"
        return False
  return True

#Takes a directory containing L2 viirs hdf files and a Set of 
#  viirs sensor bands, and returns an assembled PolarFactory object
def loadGranules(path, bands):
        print path
	# A better way to do this might be glob the directory, and create a union of all the 
	#  unique combos of _t and _d components
	files = []
	for file in os.listdir(path):
                print "considering: " + file
		if fnmatch.fnmatch(file,"GMTCO*"):
			files.append(file)
	
	#Iterate through the files, generating a datetime object and creating
	# a PolarFactory object for it. Append to the granules array
	granules = []
	for file in files:
		parts = file.split('_')
		year = int(parts[2][1:5])
		month = int(parts[2][5:7])
		day = int(parts[2][7:9])
		hour = int(parts[3][1:3])
		minute = int(parts[3][3:5])
		orbit = parts[5][1:6]
		ts = datetime.datetime(year, month, day, hour, minute)
		
		#Create the granule, and if it's ok (not a tiny file, not from 1958)
		# load the requested bands and append it to the scene
		granule = PolarFactory.create_scene("npp","1","viirs", ts, orbit)
                print ts
		if isvalidgranule(granule, bands, path):
			granule.load(bands, dir=path)
			granule.area = granule[iter(bands).next()].area
			granules.append(granule)
		else:
			break
	print "Found %d granules" % len(granules)

	return granules

#Takes an image, and single hi-res band, and performs a luminace replace on it
# The image and pan band must be in the same projection
# Does not modify the original image
def panSharpen(image, data, band):
	from mpop.imageo.geo_image import GeoImage
	pan_data = data[band].data
	pan = GeoImage((pan_data), data.area, data.time_slot, crange=(0,100)    , mode="L")
	pan.enhance(gamma=2.0)

	sharp_image = image
	sharp_image.replace_luminance(pan.channels[0])

	return sharp_image

#Iterate through all the passes we've collected, 
#  generating imagery for each one
if(len(sys.argv) < 3):
	print "Usage: process_viirs.py INPUT_DIRECTORY OUTPUT_DIRECTORY"
	print "  INPUT_DIRECTORY should look like npp.YYDDD.HHMM"
	exit(1)

#These are the bands necessary for a ghetto pan truecolor image
bands = set(["M02","M04","M05","I01"])
input_path = sys.argv[1]
output_path = sys.argv[2]

try: 
	scene_id = os.path.basename(input_path)
	print "Working on pass " + scene_id
	input_path = input_path + "/viirs"
	granules = loadGranules(input_path, bands)
	print "Data loaded"
	if(len(granules) > 0):
		print "Data Assembled"
		unprojected_data = assemble_segments(granules)
		base_filename = "{path}/{name}".format(path=output_path,name=scene_id)
		#Save the unprojected dataA
		print "Saving unprojected data"
		img = unprojected_data.image.truecolor()
		img.save("{base}_{band}_{projection}.tif".format(base=base_filename,band="truecolor",projection="satellite"))

		print "Projecting data"
		#This must be defined in $PPP_CONFIG_DIR/areas.def
		area = "alaska"
		projected_data = unprojected_data.project(area, mode="nearest")
		print "Finished projecting"

		print "Saving low-res truecolor image"
		img = projected_data.image.truecolor()
		img.save("{base}_{band}_{projection}.tif".format(base=base_filename,band="truecolor",projection=area))

		panImage = panSharpen(img, projected_data, "I01")
		print "Saving pan-sharpened truecolor image"
		panImage.save("{base}_{band}-pan_{projection}.tif".format(base=base_filename,band="truecolor",projection=area))

except Exception as inst:
	print "There was a problem with: " + scene_id
	print type(inst)
	print inst.args
	print inst
