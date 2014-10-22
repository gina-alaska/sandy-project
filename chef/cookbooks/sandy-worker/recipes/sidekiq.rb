include_recipe 'runit'
include_recipe 'chruby::system'

user node['sandy-worker']['user']

gem_package "bundler" do
  gem_binary ::File.join('/opt/rubies', node['sandy-worker']['ruby-version'], 'bin/gem')
end

git "/home/#{node['sandy-worker']['user']}/sandy-project" do
  repository node['sandy-worker']['git-repo']
  revision node['sandy-worker']['git-revision']
  action :checkout
  notifies :run, "execute[bundle-install]"
end

execute 'bundle-install' do
  command "chruby-exec #{node['sandy-worker']['ruby-version']} -- bundle install"
  cwd node['sandy-worker']['worker-dir']
  action :nothing
  notifies :restart, "runit_service[sidekiq]"
end

directory "#{node['sandy-worker']['worker-dir']}/config" do
  owner node['sandy-worker']['user']
  group node['sandy-worker']['user']
  mode 0755
end

template "#{node['sandy-worker']['worker-dir']}/config/sidekiq.yml" do
  source "sidekiq.yml.erb"
  owner node['sandy-worker']['user']
  group node['sandy-worker']['user']
  mode 0644
  variables({ queues: node['sandy-worker']['queues'] })
  notifies :restart, "runit_service[sidekiq]"
end

runit_service 'sidekiq' do
  log true
  default_logger true
  options({
    user: node['sandy-worker']['user'],
    rubyversion: node['sandy-worker']['ruby-version'],
    workerdir: node['sandy-worker']['worker-dir']
  })
end
