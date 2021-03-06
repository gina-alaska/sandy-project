#!/usr/bin/env python2 
import os
import fnmatch
import datetime
import sys
import glob
import argparse
from mpop.satellites import PolarFactory
from mpop.scene import assemble_segments
import mpop.imageo.geo_image as geo_image

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


def generate_rgb(image,r,g,b):
  image.check_channels(r, g, b)

  ch1 = image[r].data
  ch2 = image[g].data
  ch3 = image[b].data

  img = geo_image.GeoImage((ch1, ch2, ch3),
                         image.area,
                         image.time_slot,
                         mode="RGB")

  #img.enhance(stretch = "crude")

  return img


#Make lots of bands..
bands = set(["M02","M03", "M04", "M05", "M06", "M07", "M08", "I01", "I02","I03", "I04", "I05" ])

#Do command line option parsing..
parser = argparse.ArgumentParser()
parser.add_argument("-v", "--verbose", help="increase output verbosity",
                    action="store_true")
parser.add_argument("-a", "--area", help="Pytroll area definition. alaska is default.", default="alaska")
# action="store_true")
parser.add_argument("in_path", help="Input path.")
parser.add_argument("out_path", help="Output path.")
args = parser.parse_args()
if args.verbose:
  print "verbosity turned on"
  print "In: " + args.in_path
  print "Out: " + args.out_path
  print "Area: " + args.area

input_path = args.in_path
output_path = args.out_path

#Ok, ready to go, begin real work

try: 
	scene_id = os.path.basename(input_path)
	print "Working on pass " + scene_id
	input_path = input_path + "/viirs"
	granules = loadGranules(input_path, bands)
	print "Data loaded"
	if(len(granules) > 0):
                if args.verbose:
		  print "Data Assembled"
		unprojected_data = assemble_segments(granules)
		base_filename = "{path}/{name}".format(path=output_path,name=scene_id)
                if args.verbose:
		  print "Projecting data"
		#This must be defined in $PPP_CONFIG_DIR/areas.def
		area = args.area
                if args.verbose:
                  print "Using area: " + area
		projected_data = unprojected_data.project(area, mode="nearest")
                if args.verbose:
		  print "Finished projecting"

                #export individual bands
                for band in bands:
                  img = projected_data.image.channel_image(band)
                  img.enhance(gamma=2.0,stretch="crude")
		  img.save("{base}_{band}_{projection}.tif".format(base=base_filename,band=band,projection=area))

                #make a suitible bg
                bg_img = generate_rgb(projected_data.image,"I03", "I03", "I03")
                bg_img.enhance(gamma=2.0,stretch="crude")
                bg_img.save("{base}_{band}_{projection}_bg.tif".format(base=base_filename,band="543",projection=area), compression=9)
                #export 543
                img = generate_rgb(projected_data.image,"M05", "M04", "M03")
                img.save("{base}_{band}_{projection}_rgb.tif".format(base=base_filename,band="543",projection=area), compression=9)
                panImage = panSharpen(img, projected_data, "I01")
                img.merge(bg_img)
                img.enhance(stretch="crude")
                panImage.save("{base}_{band}-pan_{projection}.tif".format(base=base_filename,band="543",projection=area), compression=9)

                #export 543
                img = generate_rgb(projected_data.image,"M05", "M04", "M02")
                img.save("{base}_{band}_{projection}_rgb.tif".format(base=base_filename,band="542",projection=area), compression=9)
                panImage = panSharpen(img, projected_data, "I01")
                img.merge(bg_img)
                img.enhance(stretch="crude")
                panImage.save("{base}_{band}-pan_{projection}.tif".format(base=base_filename,band="542",projection=area), compression=9)
                #export 321
                img = generate_rgb(projected_data.image,"I03", "I02", "I01")
                img.save("{base}_{band}_{projection}_rgb.tif".format(base=base_filename,band="I321",projection=area), compression=9)
              
                

except Exception as inst:
	print "There was a problem with: " + scene_id
	print type(inst)
	print inst.args
	print inst
