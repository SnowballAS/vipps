require 'httpi'
require 'nori'
require 'hashie'
require_relative './error'
require 'vipps/communication_normalizer'

module Vipps
  class Client
    include Vipps::Configurable
    include Vipps::CommunicationNormalizer
    attr_reader :access_token

    def initialize(options = {})
      # Use options passed in, but fall back to module defaults
      Vipps::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] ||
          Vipps.instance_variable_get(:"@#{key}"))
      end
      get_access_token
    end

    def get_access_token
      headers = {
        client_id: client_id,
        client_secret: client_secret
      }
      resp = get_response("accessToken/get", :post, {}, headers)
      @acess_token = resp["access_token"]
    end

    def get_response(path, method, params, headers = nil)
      request   = build_request File.join(base_uri, path), params, headers
      response  = HTTPI.send method, request
      body = MultiJson.load(response.body, :symbolize_keys => true)
      unless response.error?
        Hashie::Mash.new(deep_underscore(body))
      else
        raise Vipps::Error.new(body)
      end
    end

    def build_request(url, params = {}, headers)
      request = HTTPI::Request.new url: url
      req_headers = headers ||  {
        "Content-Type": "application/json",
        "Authorization": "bearer #{@access_token}"
      }
      request.headers = { "Ocp-Apim-Subscription-Key": ocp_apim_access_token }.merge(req_headers)
      request.body = deep_camelize(params)
      request
    end

    # Compares client options to a Hash of requested options
    #
    # @param opts [Hash] Options to compare with current client options
    # @return [Boolean]
    def same_options?(opts)
      opts.hash == options.hash
    end

  end
end
