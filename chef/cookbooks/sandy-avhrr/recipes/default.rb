#
# Cookbook Name:: sandy-avhrr
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "polar2grid"

directory "/opt/terascan" do
  recursive true
end

mount "/opt/terascan" do
  device "say.gina.alaska.edu:/opt/terascan"
  fstype "nfs"
  options "ro"
end

