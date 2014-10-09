#!/bin/csh -f
#
# (This script is a temporary solution for geolocation file
# validation. A more robust program should be written to
# check for lat/lon incongruities, etc.)
#
# This script performs a primitive check to see if the MODIS
# geogen_modis binary has successfully created a GEO file. The
# need for this script arose because the new geogen_modis binary
# no longer returns 0 when it is successful. I believe this
# non-zero return status is due to geogen_modis looking for a
# DEM file which is not present in SeaDAS.
#
######################################################################

if ( ! ${?OCSSWROOT} ) then
  echo "`basename $0`: ERROR: The OCSSWROOT environment variable is not set. Exiting."
  echo "*** GEO file validation step skipped."
  exit 0
endif

if ($#argv != 2) then
  echo "Usage: `basename $0` GEOFILE threshold"
  echo "*** GEO file validation step skipped."
  exit 0
endif

set geofile=$1
set threshold=$2

# Check for existence of GEO file
if ( ! -f ${geofile} ) then
  echo "*** ERROR: geogen_modis failed to produce a geolocation file."
  echo "*** Validation test failed for geolocation file `basename ${geofile}`."
  exit 1
endif

# Determine location of ncdump depending on SeaDAS vs. MODISL1DB
if ( -f ${OCSSWROOT}/run/bin3/ncdump ) then
  set ncdump_cmd=${OCSSWROOT}/run/bin3/ncdump
else
    if ( -f ${OCSSWROOT}/run/bin/ncdump ) then
      set ncdump_cmd=${OCSSWROOT}/run/bin/ncdump
    else
      echo "*** ERROR: The ncdump command was not found."
      echo "*** In order to validate the geolocation file, ncdump is required..."
      echo "*** GEO file validation step skipped."
      exit 0
    endif
endif

# Commenting out the lines below, as "*" in hdf file's line causes prob on Solaris
# Check for Latitude variable in hdf file
#set test=`${ncdump_cmd} -v Latitude ${geofile} | head -3 | tail -1`
#if ("${test}" == "variables:") then
#  echo "*** ERROR: GEO file does not contain the 'Latitude' variable."
#  echo "*** Validation test failed for geolocation file `basename ${geofile}`."
#  exit 1
#endif

# Get # scans & # pixels
set nscan=`${ncdump_cmd} -v Latitude ${geofile} | head -4 | grep "scans" |cut -d"=" -f2 |cut -d";" -f1`
set npixl=`${ncdump_cmd} -v Latitude ${geofile} | head -4 | grep "frames" |cut -d"=" -f2|cut -d";" -f1`
if ((${nscan} == "") || (${npixl} == "")) then
  echo "*** ERROR: `basename ${geofile}` is empty\!"
  echo "*** Validation test failed for geolocation file `basename ${geofile}`."
  exit 1
endif

# Determine # of ncdump latitude lines containing -999
# Since the grep "-o" CLA is gnu specific, use the ncdump "-l 12" to limit
# the dump to one latitude value per line, so we can count invalid pixels
set bad=`${ncdump_cmd} -l 12 -v Latitude ${geofile} | grep -c " \-999 "`
echo "Number of pixels with missing geolocation: ${bad}"

# Compute percent of geolocated pixels to nearest integer
@ tot = ${nscan} * ${npixl}
@ good = ${tot} - ${bad}
if (${good} == 0) then
  echo "*** ERROR: No geolocated pixels found in `basename ${geofile}`."
  echo "*** Validation test failed for geolocation file `basename ${geofile}`."
  exit 1
endif

set n=`echo "scale=3; ((${good}/${tot}) + 0.005) * 100" | bc |cut -d"." -f1`
echo "Percent of geolocated pixels (rounded): ${n}"
if (${n} >= ${threshold}) then
  echo "Validation test passed for geolocation file `basename $geofile`."
  exit 0
else
  echo "*** WARNING: Percent of geolocated pixels (${n}%) is less than the specified threshold (${threshold}%)."
  echo "*** Validation test failed for geolocation file `basename ${geofile}`."
  exit 1
endif

