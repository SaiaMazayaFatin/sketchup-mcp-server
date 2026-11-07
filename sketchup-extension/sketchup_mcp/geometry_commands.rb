require_relative 'transaction_manager'

module SketchupMcp
  class GeometryCommands
    MAX_ENTITIES_CREATED = 10_000
    UNIT_TO_INCHES = {
      'mm' => 1.0 / 25.4,
      'cm' => 1.0 / 2.54,
      'm' => 1000.0 / 25.4,
      'in' => 1.0,
      'ft' => 12.0
    }.freeze

    def initialize(model_reader)
      @model_reader = model_reader
    end

    def create_box(arguments)
      origin = coordinate(arguments['origin'], arguments.fetch('origin_unit', 'mm'), allow_zero: true)
      width = length(arguments['width'])
      depth = length(arguments['depth'])
      height = length(arguments['height'])
      name = optional_name(arguments['name'])
      model = Sketchup.active_model

      result = TransactionManager.run(model, 'MCP: Create box') do
        group = model.entities.add_group
        group.name = name if name
        points = [
          Geom::Point3d.new(origin.x, origin.y, origin.z),
          Geom::Point3d.new(origin.x + width, origin.y, origin.z),
          Geom::Point3d.new(origin.x + width, origin.y + depth, origin.z),
          Geom::Point3d.new(origin.x, origin.y + depth, origin.z)
        ]
        face = group.entities.add_face(points)
        raise BridgeError.new('OPERATION_FAILED', 'Unable to create box base face') unless face

        face.pushpull(height)
        group
      end
      @model_reader.register_entity(result)
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to create box: #{error.message}")
    end

    def create_cylinder(arguments)
      center = coordinate(arguments['center'], arguments.fetch('center_unit', 'mm'), allow_zero: true)
      radius = length(arguments['radius'])
      height = length(arguments['height'])
      segments = Integer(arguments.fetch('segments', 24))
      raise BridgeError.new('INVALID_ARGUMENT', 'Segments must be between 3 and 256') unless segments.between?(3, 256)
      name = optional_name(arguments['name'])
      model = Sketchup.active_model

      result = TransactionManager.run(model, 'MCP: Create cylinder') do
        group = model.entities.add_group
        group.name = name if name
        edges = group.entities.add_circle(center, Geom::Vector3d.new(0, 0, 1), radius, segments)
        face = group.entities.add_face(edges)
        raise BridgeError.new('OPERATION_FAILED', 'Unable to create cylinder base face') unless face

        face.pushpull(height)
        group
      end
      @model_reader.register_entity(result)
    rescue ArgumentError
      raise BridgeError.new('INVALID_ARGUMENT', 'Segments must be an integer')
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to create cylinder: #{error.message}")
    end

    def create_group(arguments)
      name = optional_name(arguments['name'])
      group = TransactionManager.run(Sketchup.active_model, 'MCP: Create group') do
        result = Sketchup.active_model.entities.add_group
        result.name = name if name
        result
      end
      @model_reader.register_entity(group)
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to create group: #{error.message}")
    end

    def transform_entities(arguments)
      references = entity_references(arguments['entity_refs'])
      translation = coordinate(arguments['translation'], arguments.fetch('translation_unit', 'mm'), allow_zero: true)
      model = Sketchup.active_model
      before = references.map { |entity| @model_reader.entity_summary_for(entity) }
      TransactionManager.run(model, 'MCP: Transform entities') do
        vector = Geom::Vector3d.new(translation.x, translation.y, translation.z)
        references.each { |entity| entity.transform!(Geom::Transformation.translation(vector)) }
      end
      {
        'entities' => references.map { |entity| @model_reader.entity_summary_for(entity) },
        'before' => before
      }
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to transform entities: #{error.message}")
    end

    def delete_entities(arguments)
      unless arguments['confirm'] == true
        raise BridgeError.new('INVALID_ARGUMENT', 'Deletion requires confirm=true')
      end
      references = entity_references(arguments['entity_refs'])
      model = Sketchup.active_model
      summaries = references.map { |entity| @model_reader.entity_summary_for(entity) }
      TransactionManager.run(model, 'MCP: Delete entities') do
        references.each(&:erase!)
      end
      {
        'deleted_count' => references.length,
        'deleted_entities' => summaries
      }
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to delete entities: #{error.message}")
    end

    private

    def length(value)
      raise BridgeError.new('INVALID_ARGUMENT', 'Length must be an object with value and unit') unless value.is_a?(Hash)
      numeric = Float(value['value'])
      unit = value['unit'].to_s
      factor = UNIT_TO_INCHES[unit]
      raise BridgeError.new('INVALID_ARGUMENT', "Unsupported length unit: #{unit}") unless factor
      raise BridgeError.new('INVALID_ARGUMENT', 'Length must be greater than zero') unless numeric.finite? && numeric > 0

      numeric * factor
    rescue ArgumentError, TypeError
      raise BridgeError.new('INVALID_ARGUMENT', 'Length value must be a finite number')
    end

    def coordinate(value, unit, allow_zero: false)
      raise BridgeError.new('INVALID_ARGUMENT', 'Coordinate must contain three numbers') unless value.is_a?(Array) && value.length == 3
      values = value.map { |item| Float(item) }
      factor = UNIT_TO_INCHES[unit.to_s]
      raise BridgeError.new('INVALID_ARGUMENT', "Unsupported coordinate unit: #{unit}") unless factor
      unless values.all?(&:finite?) && (allow_zero || values.all? { |item| item >= 0 })
        raise BridgeError.new('INVALID_ARGUMENT', 'Coordinate values are invalid')
      end

      Geom::Point3d.new(*values.map { |item| item * factor })
    rescue ArgumentError, TypeError
      raise BridgeError.new('INVALID_ARGUMENT', 'Coordinate values must be finite numbers')
    end

    def optional_name(value)
      return nil if value.nil?
      raise BridgeError.new('INVALID_ARGUMENT', 'Name must be a non-empty string') unless value.is_a?(String) && !value.empty?

      value
    end

    def entity_references(value)
      raise BridgeError.new('INVALID_ARGUMENT', 'entity_refs must be a non-empty array') unless value.is_a?(Array) && !value.empty?

      value.map { |reference| @model_reader.resolve_entity(reference) }
    end
  end
end