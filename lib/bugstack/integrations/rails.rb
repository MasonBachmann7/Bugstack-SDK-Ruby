# frozen_string_literal: true

module Bugstack
  module Integrations
    # Rails integration via Railtie for automatic setup
    # and Rack middleware for exception capture.
    #
    # Add to your Gemfile:
    #   gem "bugstack"
    #
    # Configure in an initializer:
    #   # config/initializers/bugstack.rb
    #   Bugstack.init do |config|
    #     config.api_key = Rails.application.credentials.bugstack_api_key
    #     config.environment = Rails.env
    #     config.auto_fix = true
    #   end
    class Railtie < ::Rails::Railtie
      initializer "bugstack.middleware" do |app|
        app.middleware.insert(0, Bugstack::Integrations::RackMiddleware)
      end
    end if defined?(::Rails::Railtie)

    # Rack middleware that captures unhandled exceptions.
    class RackMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue Exception => e # rubocop:disable Lint/RescueException
        capture_from_rack(e, env)
        raise
      end

      private

      def capture_from_rack(exception, env)
        client = Bugstack.client
        return unless client

        request = build_request_context(env)
        client.capture_exception(
          exception,
          request: request,
          metadata: { "framework" => "rails" }
        )
      rescue => inner
        warn "[BugStack] Error capturing exception: #{inner.message}" if client&.config&.debug
      end

      def build_request_context(env)
        {
          route: env["PATH_INFO"].to_s,
          method: env["REQUEST_METHOD"].to_s
        }
      end
    end
  end
end
