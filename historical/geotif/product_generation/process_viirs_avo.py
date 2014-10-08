#!/usr/bin/env python2
import os
import fnmatch
import datetime
import glob
from mpop.scene import assemble_segments
from mpop.satellites import PolarFactory

base_path = "/mnt/raid/processing/"

#Looks at the filesize of the granule and rejects it if any
# of the files for the given bands are "too small"
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
#    return False
  for band in bands:
    values["band"] = band
    filename = granule.time_slot.strftime( pattern ) % values
    files = glob.glob(os.path.join(path,filename))
    for file in files:
      #Reject small files
      if(os.path.getsize(file) < 1000000):
        print "Tiny File"
        return False
  return True
#Takes an image, and single hi-res band, and performs a luminace replace on it
# The image and pan band must be in the same projection
# Does not modify the original image
def panSharpen(image, data, band):
        from mpop.imageo.geo_image import GeoImage
        pan_data = data[band].data
        pan = GeoImage((pan_data), data.area, data.time_slot, crange=(0,100), mode="L")
        pan.enhance(gamma=2.0)

        sharp_image = image
        sharp_image.replace_luminance(pan.channels[0])

        return sharp_image
#Iterate through all the passes we've collected, 
#  generating imagery for each one
for s in sorted(glob.glob(os.path.join(base_path,"npp.12124.*"))):
#for path in ["/mnt/npp/2012/npp.12114.1009/viirs"]:
  try: 
    scene_id = os.path.basename(s)
    print "Working on pass " + scene_id
    path= s + "/viirs"
    files = []
    #Look for files like "GMODO*"
    #  This will tell us how many granules there are and 
    #  what the timestamps are
    for file in os.listdir(path):
      if fnmatch.fnmatch(file, "GMODO*"):
        files.append(file)


    times = []
    granules = []
    #Iterate through the files, generating a datetime object and creating
    # a PolarFactory object for it. Append to the granules array
    for file in files:
      parts = file.split('_')
      year = int(parts[2][1:5])
      month = int(parts[2][5:7])
      day = int(parts[2][7:9])
      hour = int(parts[3][1:3])
      minute = int(parts[3][3:5])
      orbit = parts[5][1:6]
      ts = datetime.datetime(year, month, day, hour, minute)
      
      granule = PolarFactory.create_scene("npp","1","viirs", ts, orbit)
      bands = set(["I01","M02","M04","M05","I04","M14","M15","M16","I05"])
      if isvalidgranule(granule, bands, path):
        granule.load(bands, dir=path)
        granule.area = granule[iter(bands).next()].area
        granules.append(granule)

    #Load the necessary bands for truecolor for all the granules
    #  Temporary workaround:  copy the area of a band into the granule
    #  This allows us to reproject it.  This is a temporary fix until
    #  MPOP is patched to do this automatically
    #bands = granules[0].image.truecolor.prerequisites
    #print "I have %d granules" % len(granules)
    #for granule in granules:
      #if isvalidgranule(granule, bands,path):
        #granule.load(bands, dir=path)
        #granule.area = granule[iter(bands).next()].area
      #else:
        #granules.remove(granule)

    #This appends the granules into one big happy scene
    print "Data loaded"
    print "Now I have %d granules" % len(granules)
    if(len(granules) > 0):
      global_data = assemble_segments(granules)
      print "Data Assembled"

      #Generate the trucolor image and save it as a png and tif
      #img = global_data.image.truecolor()
      #img.save('../output/' + scene_id + '.png')
      #img.save('../output/' + scene_id + '.tif')

      #Project the image. See conf/areas.def for available definitions
      #area = "alaska_small"
      #area = "station_mask_ortho_5k"
      area = "cleveland"
      global_data.area.nprocs = 1
      local_data = global_data.project(area, mode="nearest")
  
      tc = local_data.image.truecolor()
      tc_pan = panSharpen(tc, local_data, "I01")
      tc_pan.save("{base_path}/output/{scene_id}/{scene_id}_truecolor-pan.tif".format(base_path=base_path,scene_id=scene_id))
      for band in bands:
        print "Saving {band}".format(band=band)
        img = local_data.image.channel_image(band)
        #img.save('../output/' + scene_id + '/' + scene_id + '_truecolor_' + area + '.png')
        img.save("{base_path}/output/{scene_id}/{scene_id}_{band}.tif".format(base_path=base_path,band=band,scene_id=scene_id))
        #img.save('../output/' + scene_id + '/' + scene_id + '_truecolor_' + area + '.tif')
      
  except Exception as inst:
    print "There was a problem with: " + scene_id
    print type(inst)
    print inst.args
    print inst
