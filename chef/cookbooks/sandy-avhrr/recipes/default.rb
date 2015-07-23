#
# Cookbook Name:: sandy-avhrr
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "polar2grid"
include_recipe "nfs"
include_recipe "build-essential"
include_recipe "git"
include_recipe "yum-gina"

directory "/opt/terascan" do
  recursive true
end

yum_package "glibc" do
  arch 'i686'
end

package 'csh'

mount "/opt/terascan" do
  device "say.gina.alaska.edu:/opt/terascan"
  fstype "nfs"
  options "ro"
end

file "/etc/profile.d/terascan_env.sh" do
  mode 0644
  content "source /opt/terascan/etc/tscan.bash_profile"
end

package 'mapping-tools-builds'

deploy_revision '/opt/gdal-utils' do
  repo 'https://github.com/gina-alaska/processing-utils'
  revision 'master'
  user 'processing'
  group 'processing'
  action 'deploy'
  symlinks({})
  symlink_before_migrate({})
  before_restart do
    bash 'build-gdal-tools' do
      cwd release_path
      user 'processing'
      group 'processing'
      environment({
        "PATH" => "/bin:/usr/bin:/opt/mapping_tools_builds/2015-06-08/bin",
        "LD_RUN_PATH" => "/opt/mapping_tools_builds/2015-06-08/lib:/opt/mapping_tools_builds/2015-06-08/embedded/lib"
      })
      code <<-EOC
        gcc -O3  $(gdal-config --cflags) -o bin/awips_thermal_stretch src/awips_thermal_stretch.c $(gdal-config --libs) -lm
        gcc -O3  $(gdal-config --cflags) -o bin/awips_vis_stretch src/awips_vis_stretch.c $(gdal-config --libs) -lm
        gcc -O3  $(gdal-config --cflags) -o bin/sqrt_stretch src/sqrt_stretch.c $(gdal-config --libs) -lm
      EOC
    end
  end
end

file '/etc/profile.d/gdal-utils.sh' do
  mode 0644
  content "export PATH=$PATH:/opt/gdal-utils/current/bin"
end