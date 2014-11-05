app_name = "sandy"

node[app_name]['packages'].each do |pkg|
  package pkg do
    action :install
  end
end
