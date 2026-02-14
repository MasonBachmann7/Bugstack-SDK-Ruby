# frozen_string_literal: true

module Bugstack
  # Core client for capturing and reporting errors to BugStack.
  # Thread-safe. Handles deduplication, filtering, and transport.
  class Client
    attr_reader :config

    def initialize(config)
      @config = config
      @deduplicator = Deduplicator.new(window: config.deduplication_window)
      @transport = nil

      if config.enabled && !config.dry_run
        @transport = Transport.new(
          endpoint: config.endpoint,
          api_key: config.api_key,
          timeout: config.timeout,
          max_retries: config.max_retries,
          debug: config.debug
        )
      end

      log_debug("Client initialized (endpoint=#{config.endpoint}, dry_run=#{config.dry_run})")
    end

    # Capture an exception and send it to BugStack.
    #
    # @param exception [Exception]
    # @param request [Hash, nil] { route:, method: }
    # @param metadata [Hash, nil]
    # @return [Boolean]
    def capture_exception(exception, request: nil, metadata: nil)
      do_capture(exception, request: request, metadata: metadata)
    rescue => e
      log_debug("Error during capture: #{e.message}")
      false
    end

    # Shut down the client and flush pending events.
    def shutdown
      @transport&.shutdown
      @transport = nil
    end

    private

    def do_capture(exception, request: nil, metadata: nil)
      return false unless @config.enabled

      # Check ignored errors
      if ignored?(exception)
        log_debug("Error ignored: #{exception.class.name}")
        return false
      end

      # Extract location info
      exc_type, file, function, line = Fingerprint.extract_location(exception)
      stack_trace = Fingerprint.format_backtrace(exception)

      # Build event
      event = Event.new(
        message: exception.message,
        stack_trace: stack_trace,
        file: file,
        function: function,
        exception_type: exc_type,
        fingerprint: Fingerprint.generate(exc_type, file, function, line),
        request: request,
        timestamp: Time.now.utc.iso8601,
        metadata: metadata || {}
      )

      # before_send hook
      if @config.before_send
        event = @config.before_send.call(event)
        if event.nil?
          log_debug("Event dropped by before_send")
          return false
        end
      end

      # Deduplication
      unless @deduplicator.should_send?(event.fingerprint)
        log_debug("Event deduplicated: #{event.fingerprint}")
        return false
      end

      # Build payload
      payload = event.to_payload(@config)

      # Dry run
      if @config.dry_run
        $stdout.puts "[BugStack DryRun] Would send: #{JSON.pretty_generate(payload)}"
        return true
      end

      # Enqueue for sending
      @transport&.enqueue(payload)
      log_debug("Event queued: #{event.fingerprint}")
      true
    end

    def ignored?(exception)
      @config.ignored_errors.any? do |pattern|
        case pattern
        when Class
          exception.is_a?(pattern)
        when String
          exception.message == pattern
        else
          false
        end
      end
    end

    def log_debug(msg)
      return unless @config.debug

      warn "[BugStack] #{msg}"
    end
  end
end
