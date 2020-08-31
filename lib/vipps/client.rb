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
        client_secret: client_secret,
        "Ocp-Apim-Subscription-Key": ocp_apim_access_token
      }
      resp = get_response("accessToken/get", :post, {}, headers)
      @access_token = resp["access_token"]
    end

    def draft_agreement(opts = {})
      body = {
        "currency": "NOK",
        "interval": opts[:interval] || "WEEK",
        "intervalCount": opts[:interval_count] || "1",
        "isApp": opts[:is_app] || false, # receive confirmation deeplink for app requests
        "merchantRedirectUrl": opts[:redirect_url] || "http://facilityfarm.no/vipps",
        "merchantAgreementUrl": opts[:agreement_url] || "http://facilityfarm.no/vipps_agreement",
        "customerPhoneNumber": opts[:phone],
        "price": 100, # 1 NOK
        "productDescription": "#{opts[:product]} description",
        "productName": "#{opts[:product]} subscription"
      }
      get_response("recurring/v2/agreements", :post, body)
    end

    def get_agreement(id)
      get_response("recurring/v2/agreements/#{id}", :get, {})
    end

    def charge(opts = {})
      body = {
        amount: opts[:amount],
        currency: "NOK",
        description: "#{opts[:product]} weekly charge",
        due: 2.days.from_now,
        retryDays: opts[:retry_days] || 3,
        hasPriceChanged: false
      }
      get_response("recurring/v2/agreements/#{opts[:agreement_id]}/charges", :post, body)
    end

    private

    def get_response(path, method, params, headers = {})
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
      req_headers = headers.merge({
        "Content-Type": "application/json",
        "Authorization": "bearer #{@access_token}",
        "Ocp-Apim-Subscription-Key": ocp_apim_access_token
      })
      request.headers = req_headers
      pp "HEADERS: #{request.headers.inspect}"
      request.body = params.to_json
      pp "BODY: #{request.body}    #{params}"
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
