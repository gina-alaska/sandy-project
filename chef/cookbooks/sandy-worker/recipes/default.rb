#
# Cookbook Name:: sandy-worker
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'parted'
include_recipe 'lvm'

parted_disk '/dev/vdb' do
  label_type 'gpt'
  action :mklabel
end

parted_disk '/dev/vdb' do
  part_type 'primary'
  part_start '2048s'
  part_end '100%'
  action :mkpart
end

parted_disk '/dev/vdb1' do
  flag_name 'lvm' do
  action :set_flag
end

parted_disk '/dev/vdb1' do
  file_system 'ext4'
  action :mkfs
end

lvm_physical_volume '/dev/vdb1'
lvm_volume_group 'vg_scratch' do
  physical_volumes ['/dev/vdb1']

  logical_volume 'scratch' do
    size '100%VG'
    mount_point '/mnt/scratch'
    filesystem 'ext4'
  end
end


include_recipe 'sandy-rails::worker'


#Should mount shared storage too
