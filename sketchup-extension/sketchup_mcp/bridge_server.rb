require 'json'
require 'socket'
require 'securerandom'
require 'thread'
require 'fileutils'
require 'sketchup.rb'
require_relative 'command_router'

module SketchupMcp
  class BridgeServer
    PROTOCOL_VERSION = 1
    DEFAULT_HOST = '127.0.0.1'
    DEFAULT_PORT = 43821
    MAX_REQUEST_BYTES = 1 * 1024 * 1024

    def initialize(host = DEFAULT_HOST, port = DEFAULT_PORT)
      @host = host
      @port = port
      @token = load_token
      @router = CommandRouter.new
      @running = false
      @server = nil
      @thread = nil
    end

    def start
      return if @running

      @server = TCPServer.new(@host, @port)
      @running = true
      @thread = Thread.new { accept_clients }
      puts("[SketchupMcp] bridge listening on #{@host}:#{@port}")
    rescue StandardError => error
      @running = false
      puts("[SketchupMcp] bridge failed to start: #{error.message}")
      raise
    end

    def stop
      @running = false
      @server&.close
      @thread&.join(1)
      @server = nil
      @thread = nil
    end

    private

    def accept_clients
      while @running
        begin
          client = @server.accept
          Thread.new(client) { |socket| handle_client(socket) }
        rescue IOError, Errno::EBADF
          break if @running
        rescue StandardError => error
          puts("[SketchupMcp] accept error: #{error.message}")
        end
      end
    end

    def handle_client(socket)
      socket.each_line do |line|
        break if line.bytesize > MAX_REQUEST_BYTES

        response = handle_request(line)
        socket.write("#{JSON.generate(response)}\n")
      end
    rescue IOError, SystemCallError => error
      puts("[SketchupMcp] client error: #{error.message}")
    ensure
      socket.close unless socket.closed?
    end

    def handle_request(line)
      request = JSON.parse(line)
      request_id = request['request_id'].to_s
      validate_request!(request)
      result = dispatch_on_ui_thread(request['operation'], request['arguments'] || {})
      success_response(request_id, result)
    rescue JSON::ParserError
      error_response('', 'INVALID_ENVELOPE', 'Request is not valid JSON')
    rescue BridgeError => error
      error_response(request_id, error.code, error.message)
    rescue StandardError => error
      puts("[SketchupMcp] request error: #{error.message}")
      error_response(request_id, 'INTERNAL_ERROR', 'Unexpected bridge error')
    end

    def validate_request!(request)
      raise BridgeError.new('INVALID_ENVELOPE', 'Request must be a JSON object') unless request.is_a?(Hash)
      raise BridgeError.new('UNSUPPORTED_PROTOCOL', 'Unsupported protocol version') unless request['protocol_version'] == PROTOCOL_VERSION
      raise BridgeError.new('UNAUTHENTICATED', 'Invalid authentication token') unless secure_token_match?(request['auth_token'])
      raise BridgeError.new('INVALID_ENVELOPE', 'Request ID is required') if request['request_id'].to_s.empty?
      raise BridgeError.new('INVALID_ENVELOPE', 'Operation is required') if request['operation'].to_s.empty?
      raise BridgeError.new('INVALID_ENVELOPE', 'Arguments must be an object') unless request['arguments'].nil? || request['arguments'].is_a?(Hash)
    end

    def dispatch_on_ui_thread(operation, arguments)
      result_queue = Queue.new
      UI.start_timer(0, false) do
        begin
          result_queue << [:ok, @router.dispatch(operation, arguments)]
        rescue BridgeError => error
          result_queue << [:error, error]
        rescue StandardError => error
          puts("[SketchupMcp] operation error: #{error.message}")
          result_queue << [:error, BridgeError.new('OPERATION_FAILED', error.message)]
        end
      end
      status, value = result_queue.pop
      raise value if status == :error

      value
    end

    def success_response(request_id, result)
      {
        'protocol_version' => PROTOCOL_VERSION,
        'request_id' => request_id,
        'success' => true,
        'result' => result
      }
    end

    def error_response(request_id, code, message)
      {
        'protocol_version' => PROTOCOL_VERSION,
        'request_id' => request_id,
        'success' => false,
        'error' => { 'code' => code, 'message' => message }
      }
    end

    def secure_token_match?(candidate)
      return false unless candidate.is_a?(String) && candidate.bytesize == @token.bytesize

      result = 0
      candidate.bytes.zip(@token.bytes) { |left, right| result |= left ^ right }
      result.zero?
    end

    def load_token
      path = File.join(ENV['APPDATA'] || ENV['HOME'] || Dir.home, 'SketchUpMcp', 'bridge.token')
      FileUtils.mkdir_p(File.dirname(path))
      return File.read(path).strip if File.file?(path) && File.read(path).strip.length >= 16

      token = SecureRandom.hex(32)
      File.write(path, token)
      token
    end
  end

  class BridgeError < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end
end