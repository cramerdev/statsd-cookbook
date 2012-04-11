#
# Cookbook Name:: statsd
# Recipe:: default
#
# Copyright 2011, Blank Pad Development
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "build-essential"
include_recipe "git"
include_recipe "nodejs"

user 'statsd' do
  shell '/bin/false'
end
group 'statsd' do
  members ['statsd']
  append true
end

execute "checkout statsd" do
  command "git clone -b v0.1.0 git://github.com/etsy/statsd"
  creates "#{Chef::Config['file_cache_path']}/statsd"
  cwd "#{Chef::Config['file_cache_path']}"
end

package "debhelper"

execute "build debian package" do
  command "dpkg-buildpackage -us -uc"
  creates "#{Chef::Config['file_cache_path']}/statsd_0.0.2_all.deb"
  cwd "#{Chef::Config['file_cache_path']}/statsd"
end

dpkg_package "statsd" do
  action :install
  source "#{Chef::Config['file_cache_path']}/statsd_0.0.2_all.deb"
end

template "/etc/statsd/rdioConfig.js" do
  source "rdioConfig.js.erb"
  owner 'statsd'
  group 'statsd'
  mode 0600
  notifies :restart, "service[statsd]"
end

cookbook_file "/usr/share/statsd/scripts/start" do
  source "upstart.start"
  mode 0755
end

cookbook_file "/etc/init/statsd.conf" do
  source "upstart.conf"
  mode 0644
end

user "statsd" do
  comment "statsd"
  system true
  shell "/bin/false"
end

service "statsd" do
  action [ :enable, :start ]
end
