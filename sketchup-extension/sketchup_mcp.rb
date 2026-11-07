require 'sketchup.rb'
require_relative 'sketchup_mcp/bridge_server'

module SketchupMcp
  unless defined?(@loaded)
    @loaded = true
    @bridge_server = BridgeServer.new
    @bridge_server.start
  end
end