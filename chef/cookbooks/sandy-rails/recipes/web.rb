include_recipe "sandy::application"


execute 'rake-assets-precompile' do
  command "chruby-exec #{node['sandy']['ruby']['version']} -- bundle exec rake assets:precompile"
  cwd "#{node['sandy']['paths']['application']}"
  environment({"RAILS_ENV" => node['sandy']['environment']})
  action :nothing
  user node['sandy']['account']
  group node['sandy']['account']
  subscribes :run, "git[#{node['sandy']['paths']['application']}]", :delayed
end


include_recipe "sandy::unicorn"
include_recipe "sandy::nginx"
