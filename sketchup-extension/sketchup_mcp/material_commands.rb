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

    def create_material(arguments)
      name = required_name(arguments['name'], 'Material name')
      color = parse_color(arguments['color']) if arguments.key?('color')
      model = Sketchup.active_model
      raise BridgeError.new('CONFLICT', "Material already exists: #{name}") if model.materials[name]

      material = TransactionManager.run(model, 'MCP: Create material') do
        result = model.materials.add(name)
        result.color = color if color
        result
      end
      {
        'name' => material.name.to_s,
        'display_name' => material.display_name.to_s,
        'color' => color_summary(material.color)
      }
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to create material: #{error.message}")
    end

    def create_tag(arguments)
      name = required_name(arguments['name'], 'Tag name')
      model = Sketchup.active_model
      raise BridgeError.new('CONFLICT', "Tag already exists: #{name}") if model.layers[name]

      layer = TransactionManager.run(model, 'MCP: Create tag') { model.layers.add(name) }
      {
        'name' => layer.name.to_s,
        'display_name' => layer.display_name.to_s,
        'visible' => layer.visible?
      }
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to create tag: #{error.message}")
    end

    private

    def required_name(value, label)
      raise BridgeError.new('INVALID_ARGUMENT', "#{label} must be a non-empty string") unless value.is_a?(String) && !value.empty?

      value
    end

    def parse_color(value)
      raise BridgeError.new('INVALID_ARGUMENT', 'color must contain red, green, and blue values') unless value.is_a?(Hash)

      channels = %w[red green blue].map do |channel|
        number = Integer(value[channel])
        raise BridgeError.new('INVALID_ARGUMENT', 'color channels must be between 0 and 255') unless number.between?(0, 255)

        number
      end
      alpha = value.key?('alpha') ? Integer(value['alpha']) : 255
      raise BridgeError.new('INVALID_ARGUMENT', 'color channels must be between 0 and 255') unless alpha.between?(0, 255)

      Sketchup::Color.new(*channels, alpha)
    rescue ArgumentError, TypeError
      raise BridgeError.new('INVALID_ARGUMENT', 'color channels must be integers')
    end

    def color_summary(value)
      {
        'red' => value.red,
        'green' => value.green,
        'blue' => value.blue,
        'alpha' => value.alpha
      }
    end
  end
end