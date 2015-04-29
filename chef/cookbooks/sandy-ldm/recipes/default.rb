#
# Cookbook Name:: sandy-ldm
# Recipe:: default
#
# Copyright (c) 2015 UAF-GINA, All Rights Reserved.

app = data_bag_item(:apps, node['sandy-ldm']['data_bag'])

requests = search(:node, 'roles:sandy-ldm-worker',
  filter_result: { 'ip' => ['ipaddress'] }).map do |server|
    {
      host: server['ip'],
      feedset: 'EXP',
      pattern: '.*'
    }
  end

node.override['ldm']['requests'] = app['config']['requests'] | requests
node.override['ldm']['allows'] = app['config']['allows']
node.override['ldm']['accepts'] = app['config']['accepts'] unless app['config']['accepts'].nil?
node.override['ldm']['pqacts'] = app['config']['pqacts']
node.override['ldm']['scours'] = app['config']['scours']

node.override['ldm']['source'] = app['source'] if app['source']
node.override['ldm']['version'] = app['version'] if app['version']
node.override['ldm']['checksum'] = app['checksum'] if app['checksum']


include_recipe "ldm::default"
