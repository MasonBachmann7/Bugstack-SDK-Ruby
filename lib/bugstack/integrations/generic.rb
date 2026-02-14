# frozen_string_literal: true

module Bugstack
  module Integrations
    # Generic Ruby integration that hooks into at_exit
    # to capture unhandled exceptions.
    #
    # Usage:
    #   require "bugstack"
    #   require "bugstack/integrations/generic"
    #
    #   Bugstack.init(api_key: "bs_live_...")
    #   Bugstack::Integrations::Generic.install!
    module Generic
      @installed = false

      # Install global exception hooks.
      def self.install!
        return if @installed

        @installed = true

        at_exit do
          if $! && !$!.is_a?(SystemExit)
            Bugstack.capture_exception($!)
          end
        end
      end

      # Check if hooks are installed.
      def self.installed?
        @installed
      end

      # Reset for testing.
      def self.reset!
        @installed = false
      end
    end
  end
end
