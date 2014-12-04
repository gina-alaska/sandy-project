include_recipe "git"
include_recipe "sandy::packages"
include_recipe "sandy::ruby"
include_recipe "postgresql::client"

user node['sandy']['account']

directory "/home/#{node['sandy']['account']}/.bundle" do
  owner node['sandy']['account']
  group node['sandy']['account']
  mode 00755
  action :create
end

template "/home/#{node['sandy']['account']}/.bundle/config" do
  source "bundle/config.erb"
  owner node['sandy']['account']
  group node['sandy']['account']
  variables({version: node['postgresql']['version']})
  mode 00644
end

gem_package "bundler" do
  gem_binary ::File.join('/opt/rubies', node['sandy']['ruby']['version'], 'bin/gem')
end

database_config = node['sandy']['database']

deploy node['sandy']['paths']['application'] do
  repo node['sandy']['git-repo']
  revision node['sandy']['git-revision']
  user node['sandy']['account']
  group node['sandy']['account']
  shallow_clone true
  keep_releases 10
  environment node['sandy']['environment']
  create_dirs_before_symlink #node['sandy']['rails']['shared_dirs']
  symlink_before_migrate node['sandy']['rails']['symlinks']
  migrate false

  before_symlink do
    %w{config config/initializers log tmp tmp/pids pids}.each do |dir|
      directory ::File.join(node['sandy']['paths']['shared'],dir) do
        owner node['sandy']['account']
        group node['sandy']['account']
      end
    end
    template "#{node['sandy']['paths']['shared']}/config/database.yml" do
      owner node['sandy']['account']
      group node['sandy']['account']
      mode 00644
      variables({
        environment: node['sandy']['environment'],
        database: database_config,
        hostname: node['sandy']['database']['hostname']
      })
    end
    template "#{node['sandy']['paths']['shared']}/config/initializers/sidekiq.rb" do
      source "sidekiq_initializer.rb.erb"
      owner node['sandy']['account']
      group node['sandy']['account']
      mode 0644
      variables({
        url: "redis://localhost:6379",
        namespace: "sandy_kitchen"
      })
    end
  end

  before_restart do
    execute 'bundle-install' do
      command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle install --deployment --path=#{node['sandy']['paths']['shared']}/gems"
      cwd "#{node['sandy']['paths']['application']}/current"
      environment({"BUNDLE_BUILD__PG" => "--with-pg_config=/usr/pgsql-#{node['postgresql']['version']}/bin/pg_config"})
    end
    execute 'rake-assets-precompile' do
      command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle exec rake assets:precompile"
      cwd "#{node['sandy']['paths']['application']}/current"
      environment({"RAILS_ENV" => node['sandy']['environment']})
    end
  end
end
