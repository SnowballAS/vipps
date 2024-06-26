require 'httpi'
require 'nori'
require 'hashie'
require_relative './error'
require 'vipps/communication_normalizer'

module Vipps
  class EcommClient
    include Vipps::Configurable
    include Vipps::CommunicationNormalizer
    attr_reader :access_token

    def initialize(options = {})
      # Use options passed in, but fall back to module defaults
      Vipps::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] ||
          Vipps.instance_variable_get(:"@#{key}"))
      end
      get_access_token if options[:access_token].present?
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

    def init_payment(opts = {})
      body = {
        customerInfo: {},
        merchantInfo: {
          merchantSerialNumber: @merchant_number,
          callbackPrefix: opts[:callback_url],
          fallBack: opts[:success_url],
          authToken: opts[:user_auth_token], # internal user token
        },
        transaction: {
          orderId: opts[:order_id],
          amount:  opts[:amount],
          transactionText: opts[:description],
          skipLandingPage: false
        }
      }
      get_response("ecomm/v2/payments", :post, body.deep_stringify_keys)
    end

    def capture(opts = {})
      body = {
        merchantInfo: {
          merchantSerialNumber: @merchant_number,
        },
        transaction: {
          amount: opts[:amount],
          transactionText: opts[:transaction_text]
        }
      }
      headers = { "X-Request-Id": opts[:idempotency_key] }
      get_response("ecomm/v2/payments/#{opts[:vipps_order_id]}/capture", :post, body.deep_stringify_keys, headers)
    end

    def get_order(id)
      get_response("ecomm/v2/payments/#{id}/status", :get, {})
    end

    def get_order_details(id)
      get_response("ecomm/v2/payments/#{id}/details", :get, {})
    end

    def cancel_order(order_id, description = '')
      body = {
        merchantInfo: {
          merchantSerialNumber: @merchant_number,
        },
        transaction: {
          transactionText: description
        }
      }
      get_response("ecomm/v2/payments/#{order_id}/cancel", :put, body.deep_stringify_keys)
    end

    def same_options?(opts)
      opts.hash == options.hash
    end

    private

    def get_response(path, method, params, headers = {})
      request   = build_request File.join(base_uri, path), params, headers
      response  = HTTPI.send method, request
      body = MultiJson.load(response.body, :symbolize_keys => true)
      unless response.error?
        Hashie::Mash.new(deep_underscore(body))
      else
        raise Vipps::Error.new(response.body)
      end
    end

    def build_request(url, params = {}, headers)
      request = HTTPI::Request.new url: url
      req_headers = headers.merge({
        "Content-Type": "application/json",
        "Authorization": "bearer #{@access_token}",
        "Ocp-Apim-Subscription-Key": ocp_apim_access_token,
        "Merchant-Serial-Number": @merchant_number
      })
      request.headers = req_headers
      request.body = params.to_json
      request
    end

  end
end
