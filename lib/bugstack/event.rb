# frozen_string_literal: true

require "json"
require "time"

module Bugstack
  # Represents an error event to be sent to BugStack.
  class Event
    attr_accessor :message, :stack_trace, :file, :function, :fingerprint,
                  :exception_type, :request, :environment, :timestamp, :metadata

    def initialize(
      message:,
      stack_trace: "",
      file: "",
      function: "",
      fingerprint: "",
      exception_type: "",
      request: nil,
      environment: nil,
      timestamp: nil,
      metadata: {}
    )
      @message = message
      @stack_trace = stack_trace
      @file = file
      @function = function
      @fingerprint = fingerprint
      @exception_type = exception_type
      @request = request
      @environment = environment || default_environment
      @timestamp = timestamp || Time.now.utc.iso8601
      @metadata = metadata || {}
    end

    # Serialize to the standard BugStack API payload.
    #
    # @param config [Bugstack::Configuration]
    # @return [Hash]
    def to_payload(config)
      payload = {
        "apiKey" => config.api_key,
        "error" => {
          "message" => @message,
          "stackTrace" => @stack_trace,
          "file" => @file,
          "function" => @function,
          "fingerprint" => @fingerprint
        },
        "environment" => {
          "language" => @environment[:language],
          "languageVersion" => @environment[:language_version],
          "framework" => @environment[:framework].to_s,
          "frameworkVersion" => @environment[:framework_version].to_s,
          "os" => @environment[:os],
          "sdkVersion" => @environment[:sdk_version]
        },
        "timestamp" => @timestamp
      }

      if @request
        payload["request"] = {
          "route" => @request[:route].to_s,
          "method" => @request[:method].to_s
        }
      end

      payload["projectId"] = config.project_id unless config.project_id.empty?

      meta = @metadata.dup
      meta["autoFix"] = true if config.auto_fix
      payload["metadata"] = meta unless meta.empty?

      payload
    end

    private

    def default_environment
      {
        language: "ruby",
        language_version: RUBY_VERSION,
        framework: "",
        framework_version: "",
        os: RUBY_PLATFORM,
        sdk_version: Bugstack::VERSION
      }
    end
  end
end
