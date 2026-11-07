require_relative 'transaction_manager'

module SketchupMcp
  class MaterialCommands
    def initialize(model_reader)
      @model_reader = model_reader
    end

    def apply_material(arguments)
      entity = @model_reader.resolve_entity(arguments['entity_ref'])
      material_name = arguments['material_name']
      raise BridgeError.new('INVALID_ARGUMENT', 'material_name must be a non-empty string') unless material_name.is_a?(String) && !material_name.empty?

      model = Sketchup.active_model
      material = model.materials[material_name]
      raise BridgeError.new('CONFLICT', "Material does not exist: #{material_name}") unless material

      TransactionManager.run(model, 'MCP: Apply material') do
        entity.material = material
      end
      @model_reader.entity_summary_for(entity)
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to apply material: #{error.message}")
    end

    def set_entity_tag(arguments)
      entity = @model_reader.resolve_entity(arguments['entity_ref'])
      tag_name = arguments['tag_name']
      raise BridgeError.new('INVALID_ARGUMENT', 'tag_name must be a non-empty string') unless tag_name.is_a?(String) && !tag_name.empty?

      model = Sketchup.active_model
      tag = model.layers[tag_name]
      raise BridgeError.new('CONFLICT', "Tag does not exist: #{tag_name}") unless tag

      TransactionManager.run(model, 'MCP: Set entity tag') do
        entity.layer = tag
      end
      @model_reader.entity_summary_for(entity)
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to set entity tag: #{error.message}")
    end
  end
end