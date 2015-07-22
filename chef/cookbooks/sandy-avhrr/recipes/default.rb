#
# Cookbook Name:: sandy-avhrr
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "polar2grid"

directory "/opt/terascan" do
  recursive true
end

yum_package "glibc" do
  arch 'i686'
end

package 'csh'

mount "/opt/terascan" do
  device "say.gina.alaska.edu:/opt/terascan"
  fstype "nfs"
  options "ro"
end

file "/etc/profile.d/terascan_env.sh" do
  mode 0644
  content "source /opt/terascan/etc/tscan.bash_profile"
end

