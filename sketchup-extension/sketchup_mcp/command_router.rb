require_relative 'model_reader'
require_relative 'geometry_commands'

module SketchupMcp
  class CommandRouter
    def initialize
      @model_reader = ModelReader.new
      @geometry_commands = GeometryCommands.new(@model_reader)
    end

    def dispatch(operation, arguments)
      case operation
      when 'ping_sketchup'
        { 'pong' => true }
      when 'get_sketchup_status'
        @model_reader.status
      when 'get_model_summary'
        @model_reader.summary
      when 'get_model_units'
        @model_reader.units_info
      when 'get_selection'
        @model_reader.selection
      when 'get_entity_details'
        @model_reader.entity_details(arguments)
      when 'list_entities'
        @model_reader.list_entities(arguments)
      when 'list_materials'
        @model_reader.materials
      when 'list_tags'
        @model_reader.tags
      when 'list_scenes'
        @model_reader.scenes
      when 'create_box'
        @geometry_commands.create_box(arguments)
      when 'create_cylinder'
        @geometry_commands.create_cylinder(arguments)
      when 'create_group'
        @geometry_commands.create_group(arguments)
      when 'transform_entities'
        @geometry_commands.transform_entities(arguments)
      when 'delete_entities'
        @geometry_commands.delete_entities(arguments)
      else
        raise BridgeError.new('UNAUTHORIZED_OPERATION', "Unsupported operation: #{operation}")
      end
    end
  end
end