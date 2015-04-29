#Resize /tmp and /var to be large enough for cspp to download and install
#Create /opt/cspp at 100G
include_recipe 'lvm'
include_recipe 'xfs'

lvm_logical_volume "lv_tmp" do
  group 'system'
  size '15G'
  action :resize
end

lvm_logical_volume "lv_var" do
  group 'system'
  size '15G'
  action :resize
end

directory '/opt/cspp' do
  recursive true
end

lvm_logical_volume 'lv_cspp' do
  group 'system'
  size '100G'
  filesystem 'xfs'
  mount_point '/opt/cspp'
end