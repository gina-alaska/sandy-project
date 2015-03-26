#
# Cookbook Name:: sandy-influxdb
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
node.override['influxdb']['config']['input_plugins']['graphite']['enabled'] = true
node.override['influxdb']['config']['input_plugins']['graphite']['database'] = 'sandy-metrics'

include_recipe 'influxdb::default'
