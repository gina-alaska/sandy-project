node.default['sandy']['rails']['symlinks']['config/sidekiq.yml'] = 'config/sidekiq.yml'

include_recipe 'runit'
include_recipe 'sandy::application'

concurrency = node['sandy']['worker']['concurrency'] || node['cpu']['total']

template "#{node['sandy']['paths']['config']}/sidekiq.yml" do
  source "sidekiq.yml.erb"
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 0644
  variables({
    concurrency: concurrency,
    queues: node['sandy']['worker']['queues']
  })
  notifies :restart, "runit_service[sidekiq]"
end

#Check out worker repo
#Set path information
directory node['sandy']['worker']['scripts-path'] do
  owner node['sandy']['account']
  group node['sandy']['account']
end

git node['sandy']['worker']['scripts-path'] do
  repository node['sandy']['worker']['scripts-git-repo']
  revision node['sandy']['worker']['scripts-git-revision']
  action node['sandy']['worker']['scripts-git-action']
end

execute 'bundle-install' do
  command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle install --deployment --path /home/#{node['sandy']['account']}/.bundle"
  cwd node['sandy']['worker']['scripts-path']
  user node['sandy']['account']
  group node['sandy']['account']
  action :nothing
  subscribes :run, "git[#{node['sandy']['worker']['scripts-path']}]", :delayed
end

runit_service 'sidekiq' do
  log true
  default_logger true
  env({
    "PATH" => "/usr/bin:/bin:#{node['sandy']['worker']['scripts-path']}/bin",
    "SVWAIT" => "15",
    "SANDY_SCRATCH_PATH" => node['sandy']['secrets']['scratch_path'],
    "SANDY_SHARED_PATH" => node['sandy']['secrets']['shared_path'],
    "PROCESSING_NUMBER_OF_CPUS" => "#{node['cpu']['total']}"
  })
  options({
    user: node['sandy']['account'],
    rubyversion: node['sandy']['ruby']['version'],
    app_dir: "#{node['sandy']['paths']['application']}",
    environment: node['sandy']['environment'],
    pidfile: "#{node['sandy']['paths']['application']}/tmp/sidekiq.pid"
  })
end
