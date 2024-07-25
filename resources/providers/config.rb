# Cookbook:: rb-ai
# Provider:: config

include Rbai::Helper

action :add do
  begin
    user = new_resource.user

    dnf_package 'redborder-ai' do
      action :upgrade
      flush_cache [:before]
    end

    execute 'create_user' do
      command "/usr/sbin/useradd -r #{user}"
      ignore_failure true
      not_if "getent passwd #{user}"
    end

    %w(/etc/redborder-ai).each do |path|
      directory path do
        owner user
        group user
        mode '0755'
        action :create
      end
    end

    service 'redborder-ai' do
      service_name 'redborder-ai'
      ignore_failure true
      supports status: true, restart: true, enable: true
      action [:start, :enable]
    end

    Chef::Log.info('Redborder ai cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'redborder-ai' do
      service_name 'redborder-ai'
      ignore_failure true
      supports status: true, enable: true
      action [:stop, :disable]
    end

    %w(/etc/redborder-ai).each do |path|
      directory path do
        recursive true
        action :delete
      end
    end

    dnf_package 'redborder-ai' do
      action :remove
    end

    Chef::Log.info('Redborder ai cookbook has been removed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    unless node['redborder-ai']['registered']
      query = {}
      query['ID'] = "redborder-ai-#{node['hostname']}"
      query['Name'] = 'redborder-ai'
      query['Address'] = "#{node['ipaddress']}"
      query['Port'] = 5000
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['redborder-ai']['registered'] = true
      Chef::Log.info('redborder-ai service has been registered to consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node['redborder-ai']['registered']
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/redborder-ai-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['redborder-ai']['registered'] = false
      Chef::Log.info('redborder-ai service has been deregistered from consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
