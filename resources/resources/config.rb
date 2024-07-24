# Cookbook:: rbai
# Resource:: config

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, kind_of: String, default: 'redborder-ai'
attribute :cdomain, kind_of: String, default: 'redborder.cluster'
