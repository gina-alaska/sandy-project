#!/bin/csh -f
#
# Runs geogen_modis for a single Level 1A granule
# A MODIS Aqua or Terra geolocation file is produced from a L1A file.
#
# This script is a wrapper for MODIS L1A to GEO processing:
#
# -builds the JPL planetary ephemeris binary file, as needed
# -checks dates of utcpole.dat and leapsec.dat and optionally calls
#    modis_update_utcpole_leapsec.csh to update them
# -calls the modis_timestamp binary to determine platform & start time
# -optionally calls modis_definitive_atteph.csh to determine/retrieve
#    required definitive attitude/ephemeris files
# -optionally calls modis_predicted_atteph.csh to determine/retrieve
#    required predicted attitude/ephemeris files
# -constructs the PCF file
# -calls the geogen_modis binary
# -performs rudimentary validation using modis_geocheck.csh
# -checks exit status from modis_geocheck.csh and cleans up if no error
#

######################################################################
# Version-specific variables
set collection_id = "005"
set pgeversion    = "5.0.41"
set lutversion    = "6"

######################################################################
# Set variable defaults
set definitive         = ON
set definitive_http    = ON
set predicted          = ON
set predicted_http     = ON
set utc_leap           = ON
set verbosity          = OFF
set terrain_correct    = ON
set geocheck_threshold = 95

######################################################################
# Define directory & file paths

if !($?SEADAS) then
  echo "`basename $0`: ERROR: The SEADAS environment variable is not set."
  echo "" ; exit 1
endif
if !($?OCDATAROOT) then
  echo "`basename $0`: ERROR: The OCDATAROOT environment variable is not set."
  echo "" ; exit 1
endif
if !(-d $OCDATAROOT/modis) then
  echo "`basename $0`: ERROR: The $OCDATAROOT/modis directory doesn't exist."
  echo "" ; exit 1
endif

set scripts = $SEADAS/run/scripts
set vardir  = $SEADAS/run/var/modis
set bindir  = $OCSSWROOT/run/bin
if $OCSSW_DEBUG set bindir = ${bindir}_debug

# SDPTK stuff
setenv PGSMSG $OCDATAROOT/modis/static
set pcf_template = $OCDATAROOT/modis/pcf/GEO_template.pcf
if !(-f $pcf_template) then
  echo "`basename $0`: ERROR: Could not find PCF template $pcf_template."
  echo "" ; exit 1
endif

set static = $OCDATAROOT/modis/static
if ( -d $OCDATAROOT/modis/dem ) then
  set demdir = $OCDATAROOT/modis/dem
else
  set demdir = $OCDATAROOT/modis/static
endif

######################################################################
# Parse command line
if ($#argv < 1 || $#argv > 24) goto USAGE_EXIT

set partest = `echo $1 | awk -F= '{ print $1 }'`
if ($partest == par) then # read parameters from file
  set parfile = `echo $1 | awk -F= '{ print $2 }'`
  if !(-f $parfile) then
    echo "`basename $0`: ERROR: The parameter file $parfile does not exist."
    echo "" ; exit 1
  endif

  foreach i ( `cat $parfile` )
    set pair = `echo $i | grep = | tr -d " " | tr -d "\t" | grep -v "^#"`
    if ($pair != "") then
      set keyword = `echo $pair | awk -F= '{ print $1 }'`
      set value   = `echo $pair | awk -F= '{ print $2 }'`

      if ($keyword == ifile) set l1afile = `basename $value`
      if ($keyword == ifile) set l1adir  = `dirname  $value`
      if ($keyword == o)  set user_geofile  = $value
      if ($keyword == a1) set user_attfile1 = $value
      if ($keyword == a2) set user_attfile2 = $value
      if ($keyword == e1) set user_ephfile1 = $value
      if ($keyword == e2) set user_ephfile2 = $value
      if ($keyword == disable-definitive      && $value==1) set definitive      = OFF
      if ($keyword == disable-definitive-http && $value==1) set definitive_http = OFF
      if ($keyword == disable-predicted       && $value==1) set predicted       = OFF
      if ($keyword == disable-predicted-http  && $value==1) set predicted_http  = OFF
      if ($keyword == disable-utcpole_leapsec && $value==1) set utc_leap  = OFF
      if ($keyword == verbose-http            && $value==1) set verbosity = ON
      if ($keyword == disable-dem             && $value==1) set terrain_correct = OFF
      if ($keyword == geocheck_threshold) set geocheck_threshold = $value
      if ($keyword == b                       && $value==1) set use_base = ON
      if ($keyword == save-log                && $value==1) set savelog  = ON
    endif
  end
  if !($?l1afile) then
    echo "`basename $0`: ERROR: The ifile parameter must be specified in the parameter file."
    echo "" ; exit 1
  endif

else # no par file
  @ n_inputs = 0
  while ($#argv > 0)
  switch ($1)
    case -*: # flag
      switch ($1)
        case -o:
          set user_geofile = $2
          shift; shift; breaksw
        case -a1:
          set user_attfile1 = $2
          shift; shift; breaksw
        case -a2:
          set user_attfile2 = $2
          shift; shift; breaksw
        case -e1:
          set user_ephfile1 = $2
          shift; shift; breaksw
        case -e2:
          set user_ephfile2 = $2
          shift; shift; breaksw
        case -disable-definitive:
          set definitive = OFF
          shift; breaksw
        case -disable-definitive-http:
          set definitive_http = OFF
          shift; breaksw
        case -disable-predicted:
          set predicted = OFF
          shift; breaksw
        case -disable-predicted-http:
          set predicted_http = OFF
          shift; breaksw
        case -disable-utcpole_leapsec:
          set utc_leap = OFF
          shift; breaksw
        case -verbose-http:
          set verbosity = ON
          shift; breaksw
        case -disable-dem:
          set terrain_correct = OFF
          shift; breaksw
        case -geocheck_threshold:
          set geocheck_threshold = $2
          shift; shift; breaksw
        case -b:
          set use_base = ON
          shift; breaksw
        case -save-log:
          set savelog = ON
          shift; breaksw
        default:
          goto USAGE_EXIT
      endsw
     breaksw
    default: # not a flag; must be input file
      set l1afile = `basename $1`
      set l1adir  = `dirname  $1`
      if ($n_inputs == 1) goto USAGE_EXIT
      @ n_inputs = $n_inputs + 1
      shift; breaksw
    endsw
  end

  if ($n_inputs == 0) then
    echo "`basename $0`: ERROR: No MODIS_L1A_file specified!"
    goto USAGE_EXIT
  endif
endif

if !(-f $l1adir/$l1afile) then
  echo "`basename $0`: ERROR: File $l1adir/$l1afile does not exist."
  goto USAGE_EXIT
endif
if ($?user_attfile1) then
  if !(-f $user_attfile1) then
    echo "`basename $0`: ERROR: Attitude file $user_attfile1 does not exist."
    goto USAGE_EXIT
  endif
endif
if ($?user_attfile2) then
  if !(-f $user_attfile2) then
    echo "`basename $0`: ERROR: Attitude file $user_attfile2 does not exist."
    goto USAGE_EXIT
  endif
endif
if ($?user_ephfile1) then
  if !(-f $user_ephfile1) then
    echo "`basename $0`: ERROR: Ephemeris file $user_ephfile1 does not exist."
    goto USAGE_EXIT
  endif
endif
if ($?user_ephfile2) then
  if !(-f $user_ephfile2) then
    echo "`basename $0`: ERROR: Ephemeris file $user_ephfile2 does not exist."
    goto USAGE_EXIT
  endif
endif
if (  ($?user_attfile1) && !($?user_ephfile1) ) then
  echo "ERROR: User-specified attitude, but not ephemeris."
  echo "Attitude/ephemeris must either be ALL user-specified or NO user-specified."
  goto USAGE_EXIT
endif
if ( !($?user_attfile1) &&  ($?user_ephfile1) ) then
  echo "ERROR: User-specified ephemeris, but not attitude."
  echo "Attitude/ephemeris must either be ALL user-specified or NO user-specified."
  goto USAGE_EXIT
endif
if ( $definitive == OFF && $predicted == OFF ) then
  echo "ERROR: Both definitive AND predicted attitude/ephemeris are disabled."
  echo "At least one must be enabled for processing."
  goto USAGE_EXIT
endif
if ( $terrain_correct == ON && !(-d $demdir) ) then
  echo ""
  echo "WARNING: Could not locate MODIS digital elevation maps directory:"
  echo "         '$demdir/'."
  echo ""
  echo "*TERRAIN CORRECTION DISABLED*"
  echo ""
  set terrain_correct = OFF
endif

######################################################################
# Set output directory

set rundir = .
if ($?MODIS_GEO) then
  set rundir = $MODIS_GEO
endif

if ($?user_geofile) then
  set user_rundir = `dirname $user_geofile`
  if ($user_rundir != .) then
    set rundir = $user_rundir
  endif
endif

mkdir -p $rundir; cd $rundir

######################################################################
# Determine pass start and stop times and platform

set starttime = `$bindir/modis_timestamp $l1adir/$l1afile start`
set exitstatus = $status
if ($exitstatus != 0) then
  echo "`basename $0`: ERROR: Unable to determine start time from L1A file."
  echo "" ; exit 1
endif
set year = `echo $starttime | cut -c2-5`
set doy  = `echo $starttime | cut -c6-8`
set hr   = `echo $starttime | cut -c9-10`
set mn   = `echo $starttime | cut -c11-12`
set sec  = `echo $starttime | cut -c13-14`

set stoptime = `$bindir/modis_timestamp $l1adir/$l1afile stop`
set exitstatus = $status
if ($exitstatus != 0) then
  echo "`basename $0`: ERROR: Unable to determine stop time from L1A file."
  echo "$starttime"
  echo "" ; exit 1
endif
set stopyear = `echo $stoptime | cut -c2-5`
set stopdoy  = `echo $stoptime | cut -c6-8`
set stophr   = `echo $stoptime | cut -c9-10`
set stopmn   = `echo $stoptime | cut -c11-12`
set stopsec  = `echo $stoptime | cut -c13-14`

# set sensor-specific variables
set first_letter = `echo $starttime | cut -c1`
if ($first_letter == A) then
  set sensor   = modisa
  set sat_name = aqua
  set sat_inst = PM1M
  set prefix   = MYD
  set first_letter = A
else if ($first_letter == T) then
  set sensor   = modist
  set sat_name = terra
  set sat_inst = AM1M
  set prefix   = MOD
  set first_letter = T
else
  echo "`basename $0`: ERROR: Unable to determine platform type for $l1afile."
  echo "" ; exit 1
endif

set caldir = $OCDATAROOT/$sensor/cal
set geolutfile = ${prefix}03LUT.coeff_V$pgeversion.$lutversion
set geomvrfile = maneuver_$sat_name.coeff_V$pgeversion.$lutversion
set geolutver = `grep \$Revision $caldir/$geolutfile | awk '{printf"%s",$4}'`
set geomvrver = `grep \$Revision $caldir/$geomvrfile | awk '{printf"%s",$2}'`
set mcfdir = $OCDATAROOT/$sensor/mcf
set l1amcf = ${prefix}01_$collection_id.mcf
set geomcf = ${prefix}03_$collection_id.mcf

######################################################################
# Set output filename

set BASE = ${first_letter}${year}${doy}${hr}${mn}${sec}
if ($?use_base) set BASE = `echo $l1afile | awk -F. '{ print $1 }'`
set geofile = $BASE.GEO
if ($?user_geofile) then
  set geofile = `basename $user_geofile`
endif

######################################################################
# Build the JPL planetary ephemeris binary file, as needed

set planetfile = de200.eos
if !(-f $static/$planetfile) then
  echo "Creating the $static/$planetfile binary ..."
  $LIB3_BIN/ephtobin $static/de200.dat
  if ($status != 0) then
    echo "`basename $0`: ERROR: Can't create $static/$planetfile"
    echo "" ; exit 1
  endif
  mv de200.eos $static/$planetfile
  echo ""
endif

######################################################################
# Check date of utcpole.dat and leapsec.dat and download if necessary

set timecheck1 = `find $vardir -ctime +14 -name utcpole.dat`
set timecheck2 = `find $vardir -ctime +14 -name leapsec.dat`

if ( $timecheck1 != "" || $timecheck2 != "" || \
     ! -f $vardir/utcpole.dat || \
     ! -f $vardir/leapsec.dat ) then

  if ($utc_leap == ON) then
    if ( ! -f $vardir/utcpole.dat || \
         ! -f $vardir/leapsec.dat ) then
      echo "*utcpole.dat and/or leapsec.dat not present on hard disk*"
    else
      echo "*utcpole.dat and/or leapsec.dat are more than 2 weeks old*"
    endif
    set cmd = "$scripts/modis_update_utcpole_leapsec.csh"
    if ($verbosity == ON) set cmd = "$cmd -verbose-http"
    echo ""
    echo $cmd ; $cmd ; set exitstatus = $status
    if ($exitstatus != 0) then
      echo ""
      echo "The modis_update_utcpole_leapsec.csh script returned a non-zero status!"
      echo "Please update utcpole.dat and leapsec.dat when this processing completes."
      echo ""
      echo "Attempting to continue processing..."
      echo ""
    endif
  else
    if ( ! -f $vardir/utcpole.dat || \
         ! -f $vardir/leapsec.dat ) then
      echo "`basename $0`: ERROR: utcpole.dat and/or leapsec.dat not present in"
      echo "$vardir/ and auto-downloading is disabled."
      echo ""
      echo "Please re-run without the '-disable-utcpole_leapsec' option,"
      echo "or manually download these files and re-process."
      echo "" ; exit 1
    endif
    echo "*WARNING: utcpole.dat and/or leapsec.dat are more than 2 weeks old*"
    echo ""
    echo "Auto-downloading is disabled. Attempting to continue processing..."
    echo ""
  endif
endif

######################################################################
# Determine/retrieve required ATTEPH files

set start = ${year}${doy}${hr}${mn}${sec}
set stop  = ${stopyear}${stopdoy}${stophr}${stopmn}${stopsec}

# check for user-specified atteph files
if ($?user_attfile1) then
  set atteph_type = user_provided
  set attfile1 = `basename $user_attfile1`
  set attdir1  = `dirname  $user_attfile1`
  set ephfile1 = `basename $user_ephfile1`
  set ephdir1  = `dirname  $user_ephfile1`
  if ($?user_attfile2) then
    set attfile2 = `basename $user_attfile2`
    set attdir2  = `dirname  $user_attfile2`
  else
    set attfile2 = NULL
    set attdir2  = NULL
  endif
  if ($?user_ephfile2) then
    set ephfile2 = `basename $user_ephfile2`
    set ephdir2  = `dirname  $user_ephfile2`
  else
    set ephfile2 = NULL
    set ephdir2  = NULL
  endif
  echo "Using user-specified attitude and ephemeris files."
  echo ""
  echo "att_file1: $attdir1/$attfile1"
  if ($attfile2 != NULL) then
    echo "att_file2: $attdir2/$attfile2"
  else
    echo "att_file2: NULL"
  endif
  echo "eph_file1: $ephdir1/$ephfile1"
  if ($ephfile2 != NULL) then
    echo "eph_file2: $ephdir2/$ephfile2"
  else
    echo "eph_file2: NULL"
  endif
  echo ""
  goto ATTEPH_SUCCESS
endif

# first check for definitive, then fallback to predicted
if ($definitive == ON) then
  echo "Determining required definitive attitude and ephemeris files..."
  set cmd = "$scripts/modis_definitive_atteph.csh $sat_name $start $stop"
  if ($definitive_http == OFF) set cmd = "$cmd -disable-http"
  if ($verbosity == ON)        set cmd = "$cmd -verbose-http"
  echo $cmd ; $cmd ; set exitstatus = $status
  if ($exitstatus == 0) then
    set atteph_type = definitive
    goto ATTEPH_SUCCESS
  else
    echo "*Failed to determine/retrieve required definitive attitude and ephemeris files*"
    if ($predicted == ON) then
      echo "*Falling back to predicted attitude/ephemeris*"
      echo ""
      if ($sat_name == terra) then
        set atteph_type = predicted
        goto ATTEPH_SUCCESS
      else
        echo ""
        echo "Determining required predicted attitude and ephemeris files..."
        set cmd = "$scripts/modis_predicted_atteph.csh $start $stop"
        if ($predicted_http == OFF) set cmd = "$cmd -disable-http"
        if ($verbosity == ON)       set cmd = "$cmd -verbose-http"
        echo $cmd ; $cmd ; set exitstatus = $status
        if ($exitstatus == 0) then
          set atteph_type = predicted
          goto ATTEPH_SUCCESS
        else
          echo "*Failed to determine/retrieve required predicted attitude and ephemeris files*"
          echo ""
          echo "The required attitude and ephemeris files are not available!"
          echo "Processing cannot proceed."
          echo "" ; exit 1
        endif
      endif
    else
      echo "*Use of predicted attitude and ephemeris disabled*"
      echo ""
      echo "The required attitude and ephemeris files are not available!"
      echo "Processing cannot proceed."
      echo "" ; exit 1
    endif
  endif
else
  echo "*Use of definitive attitude and ephemeris disabled*"
  if ($sat_name == terra) then
    set atteph_type = predicted
    goto ATTEPH_SUCCESS
  else
    echo ""
    echo "Determining required predicted attitude and ephemeris files..."
    set cmd = "$scripts/modis_predicted_atteph.csh $start $stop"
    if ($predicted_http == OFF) set cmd = "$cmd -disable-http"
    if ($verbosity == ON)       set cmd = "$cmd -verbose-http"
    echo $cmd ; $cmd ; set exitstatus = $status
    if ($exitstatus == 0) then
      set atteph_type = predicted
      goto ATTEPH_SUCCESS
    else
      echo "*Failed to determine/retrieve required predicted attitude and ephemeris files*"
      echo ""
      echo "The required attitude and ephemeris files are not available!"
      echo "Processing cannot proceed."
      echo "" ; exit 1
    endif
  endif
endif

# Goto tag if atteph files are available
ATTEPH_SUCCESS:

if ($atteph_type == user_provided) then
    set kinematic_state = "SDP Toolkit"
else
  if ($sat_name == terra && $atteph_type == predicted) then
    set kinematic_state = "MODIS Packet"
    set attfile1 = NULL; set attdir1 = NULL
    set attfile2 = NULL; set attdir2 = NULL
    set ephfile1 = NULL; set ephdir1 = NULL
    set ephfile2 = NULL; set ephdir2 = NULL
  else
    set kinematic_state = "SDP Toolkit"
    set att_filepath1 = `grep att_file1 .${start}.tmp_atteph_list | awk '{printf"%s",$2}'`
    set att_filepath2 = `grep att_file2 .${start}.tmp_atteph_list | awk '{printf"%s",$2}'`
    set eph_filepath1 = `grep eph_file1 .${start}.tmp_atteph_list | awk '{printf"%s",$2}'`
    set eph_filepath2 = `grep eph_file2 .${start}.tmp_atteph_list | awk '{printf"%s",$2}'`
    rm -f .${start}.tmp_atteph_list

    set attfile1 = `basename $att_filepath1`
    set attdir1  = `dirname  $att_filepath1`
    set ephfile1 = `basename $eph_filepath1`
    set ephdir1  = `dirname  $eph_filepath1`
    if ($att_filepath2 != NULL) then
      set attfile2 = `basename $att_filepath2`
      set attdir2  = `dirname  $att_filepath2`
    else
      set attfile2 = NULL
      set attdir2  = NULL
    endif
    if ($eph_filepath2 != NULL) then
      set ephfile2 = `basename $eph_filepath2`
      set ephdir2  = `dirname  $eph_filepath2`
    else
      set ephfile2 = NULL
      set ephdir2  = NULL
    endif
  endif
endif

######################################################################
# Print info

echo "Input  Level 1A   : $l1adir/$l1afile"
echo "Output Geolocation: $rundir/$geofile"
echo ""
echo "Satellite: $sat_name"
echo "Year: $year  Day: $doy  Hour: $hr  Minute: $mn"

if ($terrain_correct == ON) then
  echo "*Terrain Correction Enabled*"
  set terrain_correct = TRUE
else
  echo "*Terrain Correction Disabled*"
  set terrain_correct = FALSE
endif
echo ""

######################################################################
# Build Process Control File (pcf)

set pcf_file = $geofile.pcf
setenv PGS_PC_INFO_FILE $pcf_file

sed "\
s|L1ADIR|$l1adir|g \
s|L1AFILE|$l1afile|g \
s|GEODIR|$rundir|g \
s|GEOFILE|$geofile|g \
s|MCFDIR|$mcfdir|g \
s|L1A_MCF|$l1amcf|g \
" $pcf_template > $pcf_file.tmp1

sed "\
s|GEO_MCF|$geomcf|g \
s|CALDIR|$caldir|g \
s|GEOLUTFILE|$geolutfile|g \
s|GEOLUTVER|$geolutver|g \
s|GEOMVRFILE|$geomvrfile|g \
s|GEOMVRVER|$geomvrver|g \
" $pcf_file.tmp1 > $pcf_file.tmp2

sed "\
s|ATTDIR1|$attdir2|g \
s|ATTFILE1|$attfile2|g \
s|ATTDIR2|$attdir1|g \
s|ATTFILE2|$attfile1|g \
s|EPHDIR1|$ephdir2|g \
s|EPHFILE1|$ephfile2|g \
s|EPHDIR2|$ephdir1|g \
s|EPHFILE2|$ephfile1|g \
" $pcf_file.tmp2 > $pcf_file.tmp3

sed "\
s|DEMDIR|$demdir|g \
s|STATIC|$static|g \
s|PLANETFILE|$planetfile|g \
s|TERRAIN_CORRECT|$terrain_correct|g \
s|KINEMATIC_STATE|$kinematic_state|g \
s|VARDIR|$vardir|g \
s|LOGDIR|$rundir|g \
s|SAT_INST|$sat_inst|g \
s|PGEVERSION|$pgeversion|g \
" $pcf_file.tmp3 > $pcf_file.tmp

# delete any NULL ATT/EPH lines
sed "/^1050[12]|NULL|/d" $pcf_file.tmp > $pcf_file
rm -f $pcf_file.tmp*

######################################################################
# Run geogen_modis (MOD_PR03)

echo "Creating MODIS geolocation file..."
set exe = geogen_modis
echo $bindir/$exe ; $bindir/$exe ; set exitstatus = $status
echo "$exe exit status: $exitstatus"

echo ""
echo "Running validation test on geolocation file..".
set cmd = "$scripts/modis_geocheck.csh $geofile $geocheck_threshold"
echo $cmd ; $cmd ; set exitstatus = $status

if ($exitstatus == 0) then
# clean up
  rm -f GetAttr.temp >& /dev/null
  rm -f ShmMem       >& /dev/null
  rm -f $l1afile.met >& /dev/null
  rm -f $geofile.met >& /dev/null
  if !($?savelog) then
    rm -f $pcf_file             >& /dev/null
    rm -f Log*.$geofile >& /dev/null
  endif
  echo "MODIS geolocation processing complete."

else
# fail
  echo ""
  echo "`basename $0`: ERROR: MODIS geolocation processing failed."
  echo "Please ensure utcpole.dat and leapsec.dat are up-to-date in"
  echo "$vardir"
  echo "Please examine the LogStatus and LogUser files for more information."
  echo "" ; exit 1
endif

# successful exit
echo ""
exit 0

######################################################################
# Goto tag for usage message and exit

USAGE_EXIT:
cat << +++

Usage: `basename $0` MODIS_L1A_file [OPTIONS]

Options:

  -b                        Use base of input filename for output filenames
                            (without -b, output filenames are automatically determined)
  -o GEO_file               Output MODIS GEO HDF filename
  -a1 attitude_file1        Input attitude file 1 (chronological)
  -a2 attitude_file2        Input attitude file 2 (chronological)
  -e1 ephemeris_file1       Input ephemeris file 1 (chronological)
  -e2 ephemeris_file2       Input ephemeris file 2 (chronological)
  -disable-utcpole_leapsec  Disable auto-downloading of utcpole.dat and leapsec.dat
  -disable-definitive       Disable use of definitive attitude/ephemeris
  -disable-definitive-http  Disable auto-downloading of definitive attitude/ephemeris
  -disable-predicted        Disable use of predicted attitude/ephemeris
  -disable-predicted-http   Disable auto-downloading of predicted attitude/ephemeris
  -verbose-http             Enable verbose auto-download messages
  -disable-dem              Disable terrain elevation correction
  -geocheck_threshold n     % of geo-populated pixels required to pass geocheck validation test
  -save-log                 Save processing log file(s)

+++
exit 1
