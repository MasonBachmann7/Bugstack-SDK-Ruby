# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Bugstack
  # HTTP transport with background thread and retry logic.
  # Uses stdlib net/http — zero gem dependencies.
  class Transport
    def initialize(endpoint:, api_key:, timeout: 5.0, max_retries: 3, debug: false)
      @endpoint = URI.parse(endpoint)
      @api_key = api_key
      @timeout = timeout
      @max_retries = max_retries
      @debug = debug
      @queue = Queue.new
      @shutdown = false
      @worker = start_worker
    end

    # Add a payload to the send queue (non-blocking).
    #
    # @param payload [Hash]
    def enqueue(payload)
      return if @shutdown

      @queue << payload
    rescue => e
      log_debug("Enqueue failed: #{e.message}")
    end

    # Stop the worker thread and wait for it to finish.
    def shutdown
      @shutdown = true
      @queue << :stop
      @worker&.join(2)
    end

    private

    def start_worker
      debug = @debug
      Thread.new do
        warn "[BugStack] Transport worker started (debug=#{debug})" if debug
        loop do
          payload = @queue.pop
          break if payload == :stop

          warn "[BugStack] Worker dequeued event, sending..." if debug
          send_with_retry(payload)
        end
      rescue Exception => e
        warn "[BugStack] Worker thread crashed: #{e.class}: #{e.message}"
      end.tap { |t| t.name = "bugstack-transport" if t.respond_to?(:name=) }
    end

    def send_with_retry(payload)
      body = JSON.generate(payload)

      @max_retries.times do |attempt|
        begin
          http = Net::HTTP.new(@endpoint.host, @endpoint.port)
          http.use_ssl = @endpoint.scheme == "https"
          http.open_timeout = @timeout
          http.read_timeout = @timeout

          request = Net::HTTP::Post.new(@endpoint.request_uri)
          request["Content-Type"] = "application/json"
          request["X-BugStack-API-Key"] = @api_key
          request["X-BugStack-SDK-Version"] = Bugstack::VERSION
          request.body = body

          response = http.request(request)

          if response.code.to_i < 400
            log_debug("Event sent successfully")
            return true
          end

          log_debug("HTTP #{response.code} (attempt #{attempt + 1})")
        rescue => e
          log_debug("Send failed (attempt #{attempt + 1}): #{e.class}: #{e.message}")
        end

        # Exponential backoff: 1s, 2s, 4s
        sleep(2**attempt) if attempt < @max_retries - 1
      end

      log_debug("Max retries exceeded, dropping event")
      false
    rescue => e
      log_debug("send_with_retry crashed: #{e.class}: #{e.message}")
      false
    end

    def log_debug(msg)
      return unless @debug

      warn "[BugStack] #{msg}"
    end
  end
end
