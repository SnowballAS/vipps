module Vipps
  module CreditCards
    extend self

    VALID               = "4925000000000004".freeze
    FAILS_AUTH_AND_SALE = "4925000000000087".freeze
    FAILS_CAPTURE       = "4925000000000079".freeze

    #
    # Error:         None
    # Response code: OK
    def valid_no
      VALID
    end

    # Error:         REGISTER will go ok, but PROCESS AUTH or PROCESS SALE
    #                will fail. Use this cardnumber to validate your error
    #                handling of the PROCESS AUTH and PROCESS SALE command.
    # Response code: OK/99
    def fails_auth_and_sale_no
      FAILS_AUTH_AND_SALE
    end

    # Error:         REGISTER and PROCESS AUTH will go ok, but the PROCESS
    #                CAPTURE will fail. Use this cardnumber to validate your
    #                error handing of the PROCESS CAPTURE command.
    # Response code: OK/OK/99
    def fails_capture_no
      FAILS_CAPTURE
    end
  end
end
