# frozen_string_literal: true

module Bugstack
  module Integrations
    # Sinatra integration for capturing unhandled exceptions.
    #
    # Usage:
    #   require "sinatra"
    #   require "bugstack"
    #   require "bugstack/integrations/sinatra"
    #
    #   Bugstack.init(api_key: "bs_live_...")
    #
    #   class MyApp < Sinatra::Base
    #     register Bugstack::Integrations::Sinatra
    #
    #     get "/" do
    #       "Hello!"
    #     end
    #   end
    module Sinatra
      def self.registered(app)
        app.error do |exception|
          client = Bugstack.client
          if client
            client.capture_exception(
              exception,
              request: {
                route: request.path_info,
                method: request.request_method
              },
              metadata: { "framework" => "sinatra" }
            )
          end

          raise exception
        end
      end
    end
  end
end
