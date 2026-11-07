require_relative 'model_reader'
require_relative 'geometry_commands'
require_relative 'material_commands'
require_relative 'scene_commands'
require_relative 'preview_manager'

module SketchupMcp
  class CommandRouter
    def initialize
      @model_reader = ModelReader.new
      @geometry_commands = GeometryCommands.new(@model_reader)
      @material_commands = MaterialCommands.new(@model_reader)
      @scene_commands = SceneCommands.new
      @preview_manager = PreviewManager.new(self)
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
      when 'get_entity_children'
        @model_reader.entity_children(arguments)
      when 'search_entities'
        @model_reader.search_entities(arguments)
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
      when 'apply_material'
        @material_commands.apply_material(arguments)
      when 'set_entity_tag'
        @material_commands.set_entity_tag(arguments)
      when 'create_material'
        @material_commands.create_material(arguments)
      when 'create_tag'
        @material_commands.create_tag(arguments)
      when 'get_active_view'
        @scene_commands.active_view
      when 'create_scene'
        @scene_commands.create_scene(arguments)
      when 'set_camera'
        @scene_commands.set_camera(arguments)
      when 'preview_operation'
        preview(arguments)
      when 'execute_operation'
        execute_preview(arguments)
      when 'undo_last_operation'
        undo_last_operation
      else
        raise BridgeError.new('UNAUTHORIZED_OPERATION', "Unsupported operation: #{operation}")
      end
    end

    def previewable?(operation)
      %w[create_box create_cylinder create_group transform_entities delete_entities apply_material set_entity_tag create_material create_tag create_scene set_camera].include?(operation)
    end

    def destructive?(operation)
      %w[delete_entities].include?(operation)
    end

    def preview_summary(operation, arguments)
      case operation
      when 'delete_entities', 'transform_entities', 'apply_material', 'set_entity_tag'
        references = arguments['entity_refs'] || [arguments['entity_ref']]
        entities = references.compact.map { |reference| @model_reader.resolve_entity(reference) }
        {
          'affected_count' => entities.length,
          'affected_entities' => entities.map { |entity| @model_reader.entity_summary_for(entity) }
        }
      when 'create_box'
        { 'created_count' => 1, 'created_type' => 'Group', 'description' => 'Create a grouped box' }
      when 'create_cylinder'
        { 'created_count' => 1, 'created_type' => 'Group', 'description' => 'Create a grouped cylinder' }
      when 'create_group'
        { 'created_count' => 1, 'created_type' => 'Group', 'description' => 'Create an empty group' }
      when 'create_material'
        { 'created_count' => 1, 'created_type' => 'Material', 'description' => 'Create a model material' }
      when 'create_tag'
        { 'created_count' => 1, 'created_type' => 'Layer', 'description' => 'Create a model tag' }
      else
        { 'description' => operation }
      end
    end

    def preview(arguments)
      @preview_manager.preview(arguments)
    end

    def execute_preview(arguments)
      @preview_manager.execute(arguments)
    end

    def undo_last_operation
      model = Sketchup.active_model
      model.undo
      { 'undone' => true }
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to undo last operation: #{error.message}")
    end
  end
end