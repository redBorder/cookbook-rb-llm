# Cookbook:: rb-llm
# Provider:: config

include Rbllm::Helper

action :add do
  begin
    user = new_resource.user
    group = new_resource.group

    llm_selected_model = new_resource.llm_selected_model
    model_name = `ls /var/lib/redborder-llm/model_sources/#{llm_selected_model}`.strip

    cpus = new_resource.cpus

    # Remove redborder-ai to add redborder-llm
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

    # Add redborder-llm
    dnf_package 'redborder-llm' do
      action :upgrade
      flush_cache [:before]
    end

    execute 'create_user' do
      command "/usr/sbin/useradd -r #{user} -s /sbin/nologin"
      ignore_failure true
      not_if "getent passwd #{user}"
    end

    %w(/etc/redborder-llm /var/lib/redborder-llm var/lib/redborder-llm/model_sources).each do |path|
      directory path do
        owner user
        group user
        mode '0755'
        action :create
      end
    end

    directory "/var/lib/redborder-llm/model_sources/#{llm_selected_model}" do
      owner user
      group group
      mode '0755'
      action :create
      only_if { !llm_selected_model.nil? && !llm_selected_model.empty? }
    end

    directory '/etc/systemd/system/redborder-llm.service.d' do
      owner user
      group group
      mode '0755'
      action :create
    end

    ruby_block 'check_if_need_to_download_model' do
      block do
        dir_path = "/var/lib/redborder-llm/model_sources/#{llm_selected_model}"
        symlink_path = '/usr/lib/redborder/bin/llm-model'
        target_path = "/var/lib/redborder-llm/model_sources/#{llm_selected_model}/#{model_name}"
        service_needs_restart = false

        if Dir.exist?(dir_path) && Dir.empty?(dir_path)
          Chef::Log.info("#{dir_path} is empty, triggering run_get_llm_model")
          resources(execute: 'run_get_llm_model').run_action(:run)
          service_needs_restart = true
        elsif Dir.exist?(dir_path) && !Dir.empty?(dir_path)
          if ::File.symlink?(symlink_path) && ::File.readlink(symlink_path) == target_path
            Chef::Log.info('Symlink already points to the correct model, skipping update.')
          else
            Chef::Log.info("#{dir_path} is not empty, triggering update_llm_model")
            resources(execute: 'update_llm_model').run_action(:run)
            service_needs_restart = true
          end
        end
        resources(service: 'redborder-llm').run_action(:restart) if service_needs_restart
      end
      action :nothing
      only_if { !llm_selected_model.nil? && !llm_selected_model.empty? }
    end

    execute 'run_get_llm_model' do
      command "/usr/lib/redborder/bin/rb_get_llm_model #{llm_selected_model}"
      action :nothing
    end

    execute 'update_llm_model' do
      command "rm -f /usr/lib/redborder/bin/llm-model; ln -s /var/lib/redborder-llm/model_sources/#{llm_selected_model}/#{model_name} /usr/lib/redborder/bin/llm-model"
      action :nothing
    end

    service 'redborder-llm' do
      service_name 'redborder-llm'
      ignore_failure true
      supports status: true, restart: true, enable: true
      action [:start, :enable]
    end

    # Notify the ruby_block to check if the directory is empty after creating it
    ruby_block 'trigger_check_if_need_to_download_model' do
      block {}
      action :run
      notifies :run, 'ruby_block[check_if_need_to_download_model]', :immediately
      only_if { !llm_selected_model.nil? && !llm_selected_model.empty? }
    end

    # TEMPLATES
    template '/etc/systemd/system/redborder-llm.service.d/redborder_cpu.conf' do
      source 'redborder-llm_redborder_cpu.conf.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'rb-llm'
      variables(cpus: cpus)
      notifies :run, 'execute[systemctl-daemon-reload]', :delayed
      notifies :restart, 'service[redborder-llm]', :delayed
    end

    execute 'systemctl-daemon-reload' do
      command 'systemctl daemon-reload'
      action :nothing
    end

    Chef::Log.info('Redborder ai cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    service 'redborder-llm' do
      service_name 'redborder-llm'
      ignore_failure true
      supports status: true, enable: true
      action [:stop, :disable]
    end

    %w(/etc/redborder-llm).each do |path|
      directory path do
        recursive true
        action :delete
      end
    end

    dnf_package 'redborder-llm' do
      action :remove
    end

    Chef::Log.info('Redborder llm cookbook has been removed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    ipaddress = new_resource.ipaddress

    unless node['redborder-llm']['registered']
      query = {
        'ID' => "redborder-llm-#{node['hostname']}",
        'Name' => 'redborder-llm',
        'Address' => ipaddress,
        'Port' => 50505,
      }
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['redborder-llm']['registered'] = true
      Chef::Log.info('redborder-llm service has been registered to consul')
    end
  rescue StandardError => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node['redborder-llm']['registered']
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/redborder-llm-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['redborder-llm']['registered'] = false
      Chef::Log.info('redborder-llm service has been deregistered from consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
