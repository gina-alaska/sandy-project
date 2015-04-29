include_recipe 'ldm::_user'
include_recipe 'sandy-ldm::_ruby'
include_recipe 'sandy-ldm::_runit'

directory node['ldm-status']['home'] do
  owner 'ldm'
  group 'ldm'
  recursive true
end

directory "#{node['ldm-status']['home']}/shared" do
  owner 'ldm'
  group 'ldm'
  recursive true
end

directory "#{node['ldm-status']['home']}/shared/bundle" do
  owner 'ldm'
  group 'ldm'
  recursive true
end

directory "#{node['ldm-status']['home']}/shared/config" do
  owner 'ldm'
  group 'ldm'
  recursive true
end

deploy_revision node['ldm-status']['home'] do
  repo node['ldm-status']['repo']
  revision node['ldm-status']['revision']
  user 'ldm'
  group 'ldm'
  action 'deploy'

  before_restart do
    execute 'bundle install' do
      cwd release_path
      user 'ldm'
      group 'ldm'
      command "bundle install --without test development --path=#{node['ldm-status']['home']}/shared/bundle"
    end
  end

  notifies :usr2, 'runit_service[puma]'
end

include_recipe 'sandy-ldm::_nginx'