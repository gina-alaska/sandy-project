#
# Cookbook Name:: sandy-worker
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.


include_recipe 'sandy::worker'
include_recipe 'parted'

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
  file_system 'ext4'
  action :mkfs
end

directory '/mnt/scratch' do
  action :create
end

mount '/mnt/scratch' do
  fstype 'ext4'
  device '/dev/vdb1'
  enabled true
end

directory '/mnt/scratch/workdir' do
  owner 'processing'
  group 'processing'
  action :create
end

#Should mount shared storage too
include_recipe "gina-gluster::client"

directory '/gluster/cache' do
  recursive true
end

mount '/gluster/cache' do
  fstype 'glusterfs'
  device 'pod6.gina.alaska.edu:/gvolSatCache'
  action [:mount, :enable]
end