require 'vipps/version'
require 'vipps/configurable'
require 'vipps/client'
require 'vipps/ecomm_client'
require 'vipps/v3/client'
require 'vipps/default'


module Vipps
  class << self
    include Vipps::Configurable

    # API client based on configured options {Configurable}
    #
    # @return [Vipps::Client] API wrapper
    def client
      unless defined?(@client) && @client.same_options?(options)
        @client = Vipps::Client.new(options)
      end
      @client
    end

    # @private
    def respond_to_missing?(method_name, include_private = false)
      client.respond_to?(method_name, include_private)
    end if RUBY_VERSION >= '1.9'

    # @private
    def respond_to?(method_name, include_private = false)
      client.respond_to?(method_name, include_private) || super
    end if RUBY_VERSION < '1.9'

    private

      def method_missing(method_name, *args, &block)
        return super unless client.respond_to?(method_name)
        client.send(method_name, *args, &block)
      end
  end
  class Error < StandardError; end
  Vipps.setup
end
