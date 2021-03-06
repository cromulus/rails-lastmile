#
# Cookbook Name:: rails-bootstrap
# Recipe:: default
#
# Copyright 2013, 119 Labs LLC
#
# See license.txt for details
#
class Chef::Recipe
    # mix in recipe helpers
    include Chef::RubyBuild::RecipeHelpers
end

app_dir = node['rails-lastmile']['app_dir']
listen = node['rails-lastmile']['listen']
worker_processes = node['rails-lastmile']['worker_processes']
bundle_args = node['rails-lastmile']['bundle_args']
include_recipe "rails-lastmile::setup"
pid_file = node['rails-lastmile']['pid_file']
include_recipe "unicorn"

directory "/var/run/unicorn" do
  owner "root"
  group "root"
  mode "777"
  action :create
end

file "/var/run/unicorn/master.pid" do
  owner "root"
  group "root"
  mode "666"
  action :create_if_missing
end

file "/var/log/unicorn.log" do
  owner "root"
  group "root"
  mode "666"
  action :create_if_missing
end

template "/etc/unicorn.cfg" do
  owner "root"
  group "root"
  mode "644"
  source "unicorn.erb"
  variables(:app_dir => app_dir,
            :worker_processes=>worker_processes,
            :listen=>listen,
            :pid_file=>pid_file)
end

rvm_ruby node['rails-lastmile']['ruby_version']

rvm_gem "bundler" do
  ruby_string node['rails-lastmile']['ruby_version']
  action      :install
end

rvm_shell "run-rails" do
  ruby_string node['rails-lastmile']['ruby_version']
  cwd app_dir
  if node['rails-lastmile']['reset_db']
    code <<-EOT1
      bundle install #{node['rails-lastmile']['bundle_args']}
      bundle exec rake db:drop
      bundle exec rake db:setup
      ps -p `cat #{node['rails-lastmile']['pid_file']}` &>/dev/null || bundle exec unicorn_rails -c /etc/unicorn.cfg -D --env #{node['rails-lastmile']['environment']}
    EOT1
  else
    code <<-EOT2
      bundle install #{node['rails-lastmile']['bundle_args']}
      bundle exec rake db:migrate
      ps -p `cat #{node['rails-lastmile']['pid_file']}` &>/dev/null || bundle exec unicorn_rails -c /etc/unicorn.cfg -D --env #{node['rails-lastmile']['environment']}
    EOT2
  end
end


service "unicorn"
