#
# Cookbook Name:: sandy-db
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'parted'
include_recipe 'lvm::default'
include_recipe 'xfs'


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

parted_disk '/dev/vdb' do
  flag_name 'lvm'
  action :setflag
end

directory node['postgresql']['config']['data_directory'] do
  recursive true
end

lvm_volume_group 'vg_pg' do
  physical_volumes ['/dev/vdb1']

  logical_volume 'data' do
    size '100%VG'
    filesystem 'xfs'
    mount_point location: node['postgresql']['config']['data_directory'],
                options: 'noatime,noquota'
  end
end

include_recipe 'sandy::database'