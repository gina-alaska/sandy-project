#
# Cookbook Name:: sandy-landfall
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'lvm'

lvm_logical_volume 'lv_home' do
  group 'system'
  size '1g'
  take_up_free_space true
  action :resize
end

include_recipe 'yum-gina'

package 'gina-ruby-21'

include_recipe 'chruby'

user 'processing'

directory '/home/processing/conveyor' do
  owner 'processing'
  group 'processing'
end

directory '/home/processing/raw' do
  owner 'processing'
  group 'processing'
end

git '/home/processing/conveyor' do
  repository node['sandy']['conveyor']['git-repo']
  revision node['sandy']['conveyor']['git-revision']
  action node['sandy']['conveyor']['git-action']
  user 'processing'
  group 'processing'
end

node.override['build-essential']['compile_time'] = true
include_recipe 'build-essential'
package 'openssl-devel'

execute 'bundle-install' do
  command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle install --deployment --path /home/processing/.bundle"
  cwd '/home/processing/conveyor'
  user 'processing'
  group 'processing'
  action :nothing
  subscribes :run, "git[/home/processing/conveyor]", :delayed
end

cron 'cleanup_landingpad' do
  action :create
  minute 0
  user 'processing'
  command "find /home/processing/raw -type f -ctime +5 -delete"
end

#Should mount shared storage too
include_recipe "gina-gluster::client"

directory node['sandy']['shared_path'] do
  recursive true
end

mount node['sandy']['shared_path'] do
  fstype 'glusterfs'
  device 'pod6.gina.alaska.edu:/gvolSatCache'
  action [:mount, :enable]
end

gem_package "bundler" do
  gem_binary ::File.join('/opt/rubies', "ruby-#{node['sandy']['ruby']['version']}", 'bin/gem')
end

sandy_controller = search(:node, 'roles:sandy-controller').first
sandy_controller = node if sandy_controller.nil?

include_recipe 'runit'
runit_service 'conveyor' do
  log true
  default_logger true
  env({
    "SVWAIT" => "15",
    "LANDFALL_RAW_PATH" => node['sandy']['raw_path'],
    "LANDFALL_SHARED_PATH" => node['sandy']['shared_path'],
    "SANDY_CONTROLLER" => sandy_controller['fqdn']
    })
  options({
    user: 'processing',
    rubyversion: node['sandy']['ruby']['version'],
    path: "/home/processing/conveyor"
    })
end