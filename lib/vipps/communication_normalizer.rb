require 'active_support/core_ext'

module Vipps
  module CommunicationNormalizer
    def deep_camelize(original)
      original.inject({}) do |hash, (key,value)|
        hash.merge(key.to_s.camelize(:lower) => (value.is_a?(Hash) ? deep_camelize(value) : value))
      end
    end

    def deep_underscore(original)
      original.inject({}) do |hash, (key,value)|
        hash.merge(key.to_s.underscore => (value.is_a?(Hash) ? deep_underscore(value) : value))
      end
    end
  end
end