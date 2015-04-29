#!/bin/bash

args=("$@")
count=$#

echo "About to partition ${@}, are you sure? (y/N)"
read confirm

if [ $confirm == 'y' ]; then
  for ((I=0; I < $count; I++)); do
    disk=${args[$I]}
    if [ -b $disk ]; then
      echo "Creating raid partition on ${disk}"
      parted -s $disk mklabel gpt
      parted -s $disk mkpart primary 2048s 100%
      parted -s $disk set 1 raid on
      parted -s $disk print
    else
      echo "${disk} is not a block device"
    fi
  done
fi

echo "Name md device (ex: /dev/md2)"
read raid_device


if [ ! -b $raid_device ]; then
  mdadm -C $raid_device --level=6 --raid-devices=$(($count-1)) --spare-devices=1 ${args[@]/%/1}
else
  echo "Raid ${raid_device} already exists, skipping"
fi
