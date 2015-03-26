#
# Cookbook Name:: sandy-collectd
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

node.default['collectd']['url'] = 'http://mirrors.gina.alaska.edu/public/collectd-5.4.1.tar.gz'
node.default['collectd']['graphite_role'] = 'sandy-influxdb'
node.default['collectd']['name'] = node['hostname']
node.default['collectd']['plugins'] = {
  syslog: {
    config: {
      "LogLevel" => "Info"
    }
  },
  disk: {},
  cpu: {},
  memory: {},
  swap: {},
  disk: {},
  interface: {
    config: {
      "Interface" => "lo",
      "IgnoreSelected" => true
    }
  },
  df: {
    config: {
      "ReportReserved" => false,
      "FSType" => [ "proc", "sysfs", "fusectl", "debugfs", "devtmpfs", "devpts", "tmpfs" ],
      "IgnoreSelected" => true,
      "ReportInodes" => true
    }
  },
  write_graphite: {
    config: {
      Prefix: "servers."
    }
  }
}

include_recipe 'collectd::default'
include_recipe 'collectd::attribute_driven'
