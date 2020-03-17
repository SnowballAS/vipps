require 'Vipps/version'

module Vipps

  # Default configuration options for {Client}
  module Default

    # Default API environment
    ENVIRONMENT = :test

    # Default User Agent header string
    USER_AGENT   = "Vipps Ruby Gem #{Vipps::VERSION}".freeze

    class << self

      # Configuration options
      # @return [Hash]
      def options
        Hash[Vipps::Configurable.keys.map{|key| [key, send(key)]}]
      end

      # Vipps environment from ENV or {ENVIRONMENT}
      # @return [String]
      def environment
        ENV['VIPPS_ENVIRONMENT'] || ENVIRONMENT
      end

      # Vipps merchant id from ENV or configuration
      # @return [String]
      def client_id
        ENV['VIPPS_CLIENT_ID']
      end

      def client_secret
        ENV['VIPPS_CLIENT_SECRET']
      end

      # Vipps merchant id from ENV or configuration
      # @return [String]
      def language
        ENV['VIPPS_LANGUAGE'] || 'no_NO'
      end

      # Vipps merchant password from ENV or configuration
      # @return [String]
      def ocp_apim_access_token
        ENV['VIPPS_PRIMARY_ACCESS_TOKEN']
      end

      def ocp_apim_access_token_secondary
        ENV['VIPPS_SECONDARY_ACCESS_TOKEN']
      end

      def default_currency
        ENV['VIPPS_CURRENCY'] || "NOK"
      end

      def base_uri
        if environment == :production
          "https://api.vipps.no"
        else
          "https://apitest.vipps.no"
        end
      end

      def debug
        false
      end

      def log
        false
      end

      def log_level
        :warn
      end

      def logger
        # STDOUT
      end

      # Default User-Agent header string from ENV or {USER_AGENT}
      # @return [String]
      def user_agent
        ENV['NETENT_USER_AGENT'] || USER_AGENT
      end
    end
  end
end
