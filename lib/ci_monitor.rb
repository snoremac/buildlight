#!/usr/bin/env ruby

require 'rubygems'
require 'config'
require 'jenkins'
require 'light_controller'
require 'drivers/delcom_904006'

SLEEP = 30
keep_alive = true


@light_controllers = []

def cleanup
  @light_controllers.each { |controller| controller.stop }
end

begin
  HOSTS.each_index do |light_num|
    @light_controllers << LightController.new(Light.new(light_num), HOSTS[light_num], PROJECT_INCLUSIONS[light_num])
  end
  while keep_alive do
    @light_controllers.each(&:update_status)
    sleep SLEEP
  end
ensure
  #cleanup
  raise
end
