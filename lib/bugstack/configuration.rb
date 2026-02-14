# frozen_string_literal: true

module Bugstack
  # Configuration for the BugStack SDK.
  #
  # @example
  #   Bugstack.init do |config|
  #     config.api_key = "bs_live_..."
  #     config.environment = "production"
  #     config.auto_fix = true
  #   end
  class Configuration
    # @return [String] BugStack API key (required)
    attr_accessor :api_key

    # @return [String] BugStack API endpoint
    attr_accessor :endpoint

    # @return [String] Project identifier
    attr_accessor :project_id

    # @return [String] Environment name
    attr_accessor :environment

    # @return [Boolean] Enable autonomous error fixing
    attr_accessor :auto_fix

    # @return [Boolean] Kill switch — set to false to disable everything
    attr_accessor :enabled

    # @return [Boolean] Log SDK activity to console
    attr_accessor :debug

    # @return [Boolean] Log errors but don't send them
    attr_accessor :dry_run

    # @return [Float] Deduplication window in seconds
    attr_accessor :deduplication_window

    # @return [Float] HTTP timeout in seconds
    attr_accessor :timeout

    # @return [Integer] Max retry attempts
    attr_accessor :max_retries

    # @return [Array<Class, String>] Error types or messages to ignore
    attr_accessor :ignored_errors

    # @return [Proc, nil] Hook to inspect/modify/drop events before sending
    attr_accessor :before_send

    def initialize
      @api_key = ""
      @endpoint = "https://api.bugstack.dev/api/capture"
      @project_id = ""
      @environment = "production"
      @auto_fix = false
      @enabled = true
      @debug = false
      @dry_run = false
      @deduplication_window = 300.0
      @timeout = 5.0
      @max_retries = 3
      @ignored_errors = []
      @before_send = nil
    end
  end
end
