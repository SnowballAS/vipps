require 'httpi'
require 'nori'
require 'hashie'
require_relative '../error'
require 'vipps/communication_normalizer'

module Vipps
  module V3
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
        @access_token = resp[:access_token]
      end

      def draft_agreement(opts = {})
        body = {
          pricing: {
            type: "VARIABLE",
            currency: opts[:currency] || "NOK",
            suggestedMaxAmount: opts[:price] || 200000
          },
          interval: {
            unit: opts[:interval] || "WEEK",
            count: opts[:interval_count] || "1"
          },
          isApp: opts[:is_app] || false, # receive confirmation deeplink for app requests
          merchantAgreementUrl: opts[:agreement_url] || "http://facilityfarm.no/vipps_agreement",
          merchantRedirectUrl: opts[:redirect_url] || "http://facilityfarm.no/api/1/vipps",
          productName: opts[:product],
          productDescription: opts[:description]
        }
        body.merge!(customerPhoneNumber: opts[:phone]) unless opts[:phone].blank?
        headers = { "Idempotency-Key": opts[:idempotency_key] }
        get_response("recurring/v3/agreements", :post, body, headers)
      end

      def get_agreement(id)
        get_response("recurring/v3/agreements/#{id}", :get, {})
      end

      def update_agreement(id, opts = {})
        body = {}
        body[:status] = opts[:status] if opts[:status]
        body[:price] = opts[:price] if opts[:price]
        return if body.blank?
        get_response("recurring/v3/agreements/#{id}", :patch, body, {})
      end

      def charge(opts = {})
        body = {
          amount: opts[:amount],
          transactionType: 'DIRECT_CAPTURE',
          description: opts[:description],
          due: opts[:due] || 2.days.from_now.to_date.iso8601,
          retryDays: opts[:retry_days] || 3,
          orderId: opts[:orderId]
        }
        headers = { "Idempotency-Key": opts[:idempotency_key] }
        get_response("recurring/v3/agreements/#{opts[:agreement_id]}/charges", :post, body, headers)
      end

      def get_charge(id, agreement_id)
        get_response("recurring/v3/agreements/#{agreement_id}/charges/#{id}", :get, {})
      end

      def refund(opts = {})
        body = {
          amount: opts[:amount],
          description: opts[:description]
        }
        headers = { "Idempotency-Key": opts[:idempotency_key] }
        get_response("recurring/v3/agreements/#{opts[:agreement_id]}/charges/#{opts[:charge_id]}/refund", :post, body, headers)
      end

      # Compares client options to a Hash of requested options
      #
      # @param opts [Hash] Options to compare with current client options
      # @return [Boolean]
      def same_options?(opts)
        opts.hash == options.hash
      end

      private

      def get_response(path, method, params, headers = {})
        request   = build_request File.join(base_uri, path), params, headers
        response  = HTTPI.send method, request
        body = MultiJson.load(response.body, :symbolize_keys => true)
        unless response.error?
          body
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
          "Merchant-Serial-Number": @merchant_number,
          "Vipps-System-Name": 'Snowball_v3',
          "Vipps-System-Plugin-Name": 'Snowball-webshop_v3'
        })
        request.headers = req_headers
        request.body = params.to_json
        request
      end
    end
  end
end
