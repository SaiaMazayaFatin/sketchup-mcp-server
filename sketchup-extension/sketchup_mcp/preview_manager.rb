require 'securerandom'

module SketchupMcp
  class PreviewManager
    EXPIRATION_SECONDS = 300

    def initialize(router)
      @router = router
      @previews = {}
    end

    def preview(arguments)
      operation = arguments['operation'].to_s
      operation_arguments = arguments['arguments']
      raise BridgeError.new('INVALID_ARGUMENT', 'Preview operation is required') if operation.empty?
      raise BridgeError.new('INVALID_ARGUMENT', 'Preview arguments must be an object') unless operation_arguments.is_a?(Hash)
      raise BridgeError.new('UNAUTHORIZED_OPERATION', "Operation cannot be previewed: #{operation}") unless @router.previewable?(operation)

      preview_id = "preview_#{SecureRandom.hex(16)}"
      expires_at = Time.now.to_i + EXPIRATION_SECONDS
      summary = @router.preview_summary(operation, operation_arguments)
      @previews[preview_id] = {
        'operation' => operation,
        'arguments' => operation_arguments,
        'expires_at' => expires_at
      }
      {
        'preview_id' => preview_id,
        'protocol_version' => 1,
        'operation' => operation,
        'summary' => summary,
        'requires_confirmation' => @router.destructive?(operation),
        'expires_at' => expires_at
      }
    end

    def execute(arguments)
      preview_id = arguments['preview_id'].to_s
      raise BridgeError.new('INVALID_ARGUMENT', 'preview_id is required') if preview_id.empty?

      preview = @previews.delete(preview_id)
      raise BridgeError.new('STALE_REFERENCE', 'Preview does not exist or was already executed') unless preview
      if preview['expires_at'] <= Time.now.to_i
        raise BridgeError.new('OPERATION_TIMEOUT', 'Preview has expired')
      end
      if @router.destructive?(preview['operation']) && arguments['confirm'] != true
        @previews[preview_id] = preview
        raise BridgeError.new('INVALID_ARGUMENT', 'Execution requires confirm=true')
      end

      execution_arguments = preview['arguments'].dup
      execution_arguments['confirm'] = true if @router.destructive?(preview['operation'])
      @router.dispatch(preview['operation'], execution_arguments)
    rescue BridgeError
      raise
    rescue StandardError => error
      raise BridgeError.new('UNKNOWN_COMPLETION', "Preview execution state is unknown: #{error.message}")
    end
  end
end
