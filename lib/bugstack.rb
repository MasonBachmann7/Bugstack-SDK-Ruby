# frozen_string_literal: true

require_relative "bugstack/version"
require_relative "bugstack/configuration"
require_relative "bugstack/event"
require_relative "bugstack/fingerprint"
require_relative "bugstack/transport"
require_relative "bugstack/client"

# BugStack SDK for Ruby — capture, report, and auto-fix production errors.
#
# Usage:
#   Bugstack.init(api_key: "bs_live_...")
#
#   begin
#     risky_operation
#   rescue => e
#     Bugstack.capture_exception(e)
#   end
module Bugstack
  class Error < StandardError; end

  class << self
    # @return [Bugstack::Client, nil]
    attr_reader :client

    # Initialize the BugStack SDK.
    #
    # @param api_key [String] Your BugStack API key (required)
    # @yield [config] Optional block for configuration
    # @return [Bugstack::Client]
    def init(api_key: nil, **options, &block)
      config = Configuration.new
      config.api_key = api_key if api_key
      options.each { |k, v| config.public_send(:"#{k}=", v) }
      yield config if block_given?

      @client&.shutdown
      @client = Client.new(config)
    end

    # Capture an exception and send it to BugStack.
    #
    # @param exception [Exception]
    # @param request [Hash, nil] Request context
    # @param metadata [Hash, nil] Additional metadata
    # @return [Boolean]
    def capture_exception(exception, request: nil, metadata: nil)
      unless @client
        warn "[BugStack] Not initialized. Call Bugstack.init first."
        return false
      end

      @client.capture_exception(exception, request: request, metadata: metadata)
    end

    # Flush pending events and shut down.
    def shutdown
      @client&.shutdown
      @client = nil
    end
  end
end
