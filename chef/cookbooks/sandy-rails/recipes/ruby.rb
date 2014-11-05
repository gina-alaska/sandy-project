include_recipe "yum-gina"

package node['sandy']['ruby']['package'] do
  action :install
end

include_recipe "chruby"
