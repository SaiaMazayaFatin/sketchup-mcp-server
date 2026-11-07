require_relative 'transaction_manager'

module SketchupMcp
  class SceneCommands
    def active_view
      view = Sketchup.active_model.active_view
      camera = view.camera
      {
        'camera' => camera_data(camera),
        'viewport' => { 'width' => view.vpwidth, 'height' => view.vpheight }
      }
    rescue StandardError => error
      raise BridgeError.new('MODEL_NOT_READY', "Unable to read active view: #{error.message}")
    end

    def create_scene(arguments)
      name = arguments['name']
      raise BridgeError.new('INVALID_ARGUMENT', 'Scene name must be a non-empty string') unless name.is_a?(String) && !name.empty?

      model = Sketchup.active_model
      raise BridgeError.new('CONFLICT', "Scene already exists: #{name}") if model.pages[name]

      page = TransactionManager.run(model, 'MCP: Create scene') do
        model.pages.add(name)
      end
      scene_data(page)
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to create scene: #{error.message}")
    end

    def set_camera(arguments)
      position = point(arguments['position'])
      target = point(arguments['target'])
      up = point(arguments.fetch('up', [0, 0, 1]))
      model = Sketchup.active_model
      TransactionManager.run(model, 'MCP: Set camera') do
        model.active_view.camera = Sketchup::Camera.new(position, target, up)
      end
      active_view
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('OPERATION_FAILED', "Unable to set camera: #{error.message}")
    end

    private

    def point(value)
      raise BridgeError.new('INVALID_ARGUMENT', 'Camera vectors must contain three numbers') unless value.is_a?(Array) && value.length == 3

      values = value.map { |item| Float(item) }
      raise BridgeError.new('INVALID_ARGUMENT', 'Camera vectors must contain finite numbers') unless values.all?(&:finite?)

      Geom::Point3d.new(*values)
    rescue ArgumentError, TypeError
      raise BridgeError.new('INVALID_ARGUMENT', 'Camera vectors must contain numbers')
    end

    def camera_data(camera)
      {
        'position' => point_array(camera.eye),
        'target' => point_array(camera.target),
        'up' => point_array(camera.up),
        'perspective' => camera.perspective?
      }
    end

    def point_array(point)
      [point.x, point.y, point.z]
    end

    def scene_data(page)
      {
        'name' => page.name.to_s,
        'index' => page.index,
        'description' => page.description.to_s
      }
    end
  end
end