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
            suggestedMaxAmount: opts[:price] || 300000
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
        body.merge!(phoneNumber: opts[:phone]) if opts[:phone].to_s.length >= 8
        headers = { "Idempotency-Key": opts[:idempotency_key] }
        get_response("recurring/v3/agreements", :post, body, headers)
      end

      def get_agreement(id)
        get_response("recurring/v3/agreements/#{id}", :get, {})
      end

      def get_agreements
        get_response("recurring/v3/agreements", :get, {})
      end

      def update_agreement(id, opts = {})
        body = {}
        body[:status] = opts[:status] if opts[:status]
        body[:pricing] = { suggestedMaxAmount: opts[:price] } if opts[:price]
        return if body.blank?
        headers = { "Idempotency-Key": opts[:idempotency_key] }
        get_response("recurring/v3/agreements/#{id}", :patch, body, headers)
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

      def get_charge_by_id(id)
        get_response("recurring/v3/charges/#{id}", :get, {})
      end

      def get_charges(agreement_id)
        get_response("recurring/v3/agreements/#{agreement_id}/charges", :get, {})
      end

      def refund(opts = {})
        body = {
          amount: opts[:amount],
          description: opts[:description]
        }
        headers = { "Idempotency-Key": opts[:idempotency_key] }
        get_response("recurring/v3/agreements/#{opts[:agreement_id]}/charges/#{opts[:charge_id]}/refund", :post, body, headers)
      end

      def multiple_charge(orders = [], idempotency_key = nil)
        body = orders.map do |order|
          order.transform_keys! { |key| key.to_s.camelize(:lower) }
          order[:transactionType] ||= 'DIRECT_CAPTURE'
          order
        end
        headers = { "Idempotency-Key": idempotency_key || SecureRandom.hex(15) }
        get_response('recurring/v3/agreements/charges', :post, body, headers)
      end

      def cancel_charge(agreement_id, charge_id)
        headers = { "Idempotency-Key": SecureRandom.hex(15) }
        get_response("recurring/v3/agreements/#{agreement_id}/charges/#{charge_id}", :delete, {}, headers)
      end

      def capture(opts = {})
        body = {
          amount: opts[:amount],
          description: opts[:description]
        }
        headers = { "Idempotency-Key": opts[:idempotency_key] || SecureRandom.hex(15) }
        get_response("recurring/v3/agreements/#{opts[:agreement_id]}/charges/#{opts[:charge_id]}/capture", :post, body, headers)
      end

      def register_webhook(opts = {})
        body = {
          events: opts[:events],
          url: opts[:url]
        }
        get_response("webhooks/v1/webhooks", :post, body)
      end

      def get_webhooks
        get_response("webhooks/v1/webhooks", :get, {})
      end

      def delete_webhook(id)
        get_response("webhooks/v1/webhooks/#{id}", :delete, {})
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
        response  = HTTPI.request method, request
        body = MultiJson.load(response.body, :symbolize_keys => true) rescue ""
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
          "Vipps-System-Version": Vipps::VERSION,
          "Vipps-System-Name": 'Snowball_v3',
          "Vipps-System-Plugin-Name": 'Snowball-webshop_v3',
          "Vipps-System-Plugin-Version": Vipps::VERSION
        })
        request.headers = req_headers
        request.body = params.to_json
        request
      end
    end
  end
end
