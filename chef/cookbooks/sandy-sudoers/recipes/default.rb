#
# Cookbook Name:: sandy-sudoers
# Recipe:: default
#
# Copyright (C) 2014 UAF-GINA
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

admins = Array.new
data_bag("users").each do |account|
  u = data_bag_item("users", account)
  if u['admin']
    username = u['username'] || u['id']
    admins << username

    #Taken from user::data_bags, be consistant with how users get added
    user_account username do
    %w{comment uid gid home shell password system_user manage_home create_group
      ssh_keys ssh_keygen non_unique}.each do |attr|
        send(attr, u[attr]) if u[attr]
      end
      action Array(u['action']).map { |a| a.to_sym } if u['action']
    end

    unless u['groups'].nil? || u['action'] == 'remove'
      u['groups'].each do |groupname|
        group groupname do
          members username
          append true
        end
      end
    end
  end
end

group "wheel" do
  members admins
  action [:manage]
end

node.set['authorization']['sudo']['groups'] = [admin_group]

include_recipe "sudo::default"
