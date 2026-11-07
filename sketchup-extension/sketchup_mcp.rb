require 'sketchup.rb'
require_relative 'sketchup_mcp/bridge_server'

module SketchupMcp
  VERSION = '0.1.0' unless const_defined?(:VERSION)

  unless defined?(@loaded)
    @loaded = true
    @bridge_server = BridgeServer.new
    @bridge_server.start
  end
end