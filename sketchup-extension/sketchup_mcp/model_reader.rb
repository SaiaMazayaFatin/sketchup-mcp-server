module SketchupMcp
  class ModelReader
    MAX_ENTITIES = 500
    MAX_DEPTH = 8

    def initialize
      @references = {}
    end

    def register_entity(entity)
      entity_summary(entity, true)
    end

    def resolve_entity(reference)
      entity = @references[reference.to_s]
      raise BridgeError.new('STALE_REFERENCE', 'Entity reference is not valid for the active model') unless entity && entity.valid?

      entity
    end

    def entity_summary_for(entity)
      entity_summary(entity, true)
    end

    def status
      model = Sketchup.active_model
      {
        'connected' => true,
        'sketchup_version' => Sketchup.version,
        'platform' => RUBY_PLATFORM,
        'model_name' => model.title.to_s,
        'model_path' => model.path.to_s,
        'model_modified' => model.modified?,
        'selection_count' => model.selection.length,
        'entity_counts' => entity_counts(model),
        'units' => units_info
      }
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read active model: #{error.message}")
    end

    def summary
      model = active_model
      {
        'model_name' => model.title.to_s,
        'model_path' => model.path.to_s,
        'model_modified' => model.modified?,
        'sketchup_version' => Sketchup.version,
        'platform' => RUBY_PLATFORM,
        'units' => units_info,
        'entity_counts' => entity_counts(model),
        'bounds' => bounds(model.entities),
        'selection_count' => model.selection.length,
        'material_count' => model.materials.length,
        'tag_count' => model.layers.length,
        'scene_count' => model.pages.length
      }
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read model summary: #{error.message}")
    end

    def units_info
      options = active_model.options['UnitsOptions']
      {
        'length_format' => options['LengthFormat'],
        'length_unit' => options['LengthUnit'],
        'length_precision' => options['LengthPrecision']
      }
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read model units: #{error.message}")
    end

    def selection
      model = active_model
      {
        'count' => model.selection.length,
        'entities' => model.selection.map { |entity| entity_summary(entity) }
      }
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read selection: #{error.message}")
    end

    def entity_details(arguments)
      entity = resolve_entity(arguments['entity_ref'])
      entity_summary(entity, true)
    end

    def list_entities(arguments)
      limit = bounded_limit(arguments['limit'])
      offset = Integer(arguments.fetch('offset', 0))
      raise BridgeError.new('INVALID_ARGUMENT', 'Offset must be zero or greater') if offset.negative?

      entities = active_model.entities.to_a
      type_filter = arguments['entity_types']
      unless type_filter.nil?
        raise BridgeError.new('INVALID_ARGUMENT', 'entity_types must be an array') unless type_filter.is_a?(Array)
        entities = entities.select { |entity| type_filter.include?(entity_type(entity)) }
      end
      page = entities.drop(offset).first(limit)
      {
        'entities' => page.map { |entity| entity_summary(entity) },
        'offset' => offset,
        'limit' => limit,
        'total_matching' => entities.length,
        'next_offset' => offset + page.length < entities.length ? offset + page.length : nil,
        'truncated' => offset + page.length < entities.length
      }
    rescue ArgumentError
      raise BridgeError.new('INVALID_ARGUMENT', 'Offset must be an integer')
    end

    def materials
      active_model.materials.map do |material|
        {
          'name' => material.name.to_s,
          'display_name' => material.display_name.to_s,
          'color' => color(material.color),
          'texture' => material.texture ? material.texture.filename.to_s : nil
        }
      end
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read materials: #{error.message}")
    end

    def tags
      active_model.layers.map do |layer|
        {
          'name' => layer.name.to_s,
          'display_name' => layer.display_name.to_s,
          'visible' => layer.visible?
        }
      end
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read tags: #{error.message}")
    end

    def scenes
      active_model.pages.map do |page|
        {
          'name' => page.name.to_s,
          'index' => page.index,
          'description' => page.description.to_s
        }
      end
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read scenes: #{error.message}")
    end

    private

    def active_model
      model = Sketchup.active_model
      raise BridgeError.new('MODEL_NOT_READY', 'No active SketchUp model') unless model

      model
    end

    def bounded_limit(value)
      limit = value.nil? ? MAX_ENTITIES : Integer(value)
      raise BridgeError.new('INVALID_ARGUMENT', 'Limit must be greater than zero') if limit <= 0
      raise BridgeError.new('LIMIT_EXCEEDED', "Limit cannot exceed #{MAX_ENTITIES}") if limit > MAX_ENTITIES

      limit
    rescue ArgumentError
      raise BridgeError.new('INVALID_ARGUMENT', 'Limit must be an integer')
    end

    def resolve_entity(reference)
      resolve_entity(reference)
    end

    def entity_summary(entity, detailed = false)
      reference = reference_for(entity)
      result = {
        'entity_ref' => reference,
        'type' => entity_type(entity),
        'name' => entity.respond_to?(:name) ? entity.name.to_s : nil,
        'bounds' => bounds(entity.bounds)
      }
      if detailed
        result['persistent_id'] = entity.persistent_id if entity.respond_to?(:persistent_id)
        result['transformation'] = entity.transformation.to_a if entity.respond_to?(:transformation)
        result['layer'] = entity.layer.name.to_s if entity.respond_to?(:layer) && entity.layer
        result['material'] = entity.material.name.to_s if entity.respond_to?(:material) && entity.material
      end
      result
    end

    def reference_for(entity)
      existing = @references.key(entity)
      return existing if existing

      reference = "entity_#{SecureRandom.hex(16)}"
      @references[reference] = entity
      reference
    end

    def entity_type(entity)
      entity.class.name.split('::').last
    end

    def bounds(bounds)
      return nil unless bounds.valid?

      {
        'min' => point(bounds.min),
        'max' => point(bounds.max),
        'width' => bounds.width,
        'height' => bounds.height,
        'depth' => bounds.depth
      }
    end

    def point(value)
      [value.x, value.y, value.z]
    end

    def color(value)
      return nil unless value

      { 'red' => value.red, 'green' => value.green, 'blue' => value.blue, 'alpha' => value.alpha }
    end

    def entity_counts(model)
      entities = model.entities
      {
        'edges' => entities.grep(Sketchup::Edge).length,
        'faces' => entities.grep(Sketchup::Face).length,
        'groups' => entities.grep(Sketchup::Group).length,
        'component_instances' => entities.grep(Sketchup::ComponentInstance).length,
        'images' => entities.grep(Sketchup::Image).length
      }
    end

  end
end