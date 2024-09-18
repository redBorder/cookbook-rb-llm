# Cookbook:: rb-ai
# Resource:: config

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, kind_of: String, default: 'redborder-ai'
attribute :group, kind_of: String, default: 'redborder-ai'
attribute :cdomain, kind_of: String, default: 'redborder.cluster'
attribute :ai_selected_model, kind_of: String
attribute :ipaddress, kind_of: String, default: '127.0.0.1'
attribute :cpus, kind_of: String, default: '0'
