#
# Alpha Card Payment Gateway
#
#
# TODO include billing and shipping address fields
#
# cvv: not provided by Spree?
#
module Spree
  class Gateway::AlphaCardGateway < Gateway

    preference :login, :string
    preference :password, :string



    def provider_class
      self.class
    end

    def provider
      ::AlphaCard
    end

    def auto_capture?
      true
    end

    def payment_profiles_supported?
      false
    end

    def test?
      preferred_test_mode
    end

    def actions
      # %w(credit)
      []
    end





    def purchase money, credit_card, options = {}
      logger.debug "-"*1024
      logger.debug "AlphaCardGateway#purchase..."

      opts = {
        type: 'sale',
        email: options[:email],
        orderid: options[:order_id],
        ipaddress: options[:ip],
      }
      add_money! opts, money, options
      add_credit_card! opts, credit_card

      res = ::AlphaCard.request opts, account

      logger.debug res.inspect
      logger.debug "-"*1024

      ActiveMerchant::Billing::Response.new res.success?, "AlphaCardGateway#purchase: #{res.text}", res.data, response_params(res)
    end



    # TODO implement #credit to support credit & refund in admin area
    #
    # problem: cc number is not stored, therefore payment profiles at gateway is probably required & needs to be implemented
    #
    #
    # STATUS current implementation does not work!
    #
    def credit money, reference, options = {}
      logger.debug "-"*1024
      logger.debug "AlphaCardGateway#credit..."

      opts = {type: 'credit'}
      add_money! opts, money, currency: options[:originator].payment.currency
      add_credit_card! opts, options[:originator].payment.source

      res = ::AlphaCard.request opts, account

      logger.debug "-"*1024

      ActiveMerchant::Billing::Response.new res.success?, "AlphaCardGateway#credit: #{res.text}", res.data, response_params(res)
    end



    protected

    def spree_money_to_alpha_card cents
      "%.2f" % (cents / 100.0)
    end

    def add_money! opts, money, options
      opts[:amount] = spree_money_to_alpha_card money
      opts[:currency] = options[:currency]

      if options[:tax].present?
        opts[:tax] = spree_money_to_alpha_card options[:tax]
      end
      if options[:shipping].present?
        opts[:shipping] = spree_money_to_alpha_card options[:shipping]
      end

      opts
    end

    def add_credit_card! opts, cc
      month = cc.month.to_i
      year = cc.year.to_i - 2000
      exp = "%02d%02d" % [month, year]

      opts.merge!  ccnumber: cc.number, ccexp: exp
    end

    def response_params result
      options = {
        test: test?,
        authorization: result.data['authcode'],
        avs_result: result.data['avsresponse'].presence,
        cvv_result: result.data['cvvresponse'].presence,
      }

      unless result.success?
        options[:error_code] = result.data['response_code']
      end

      options
    end


    def account
      @account ||= ::AlphaCard::Account.new preferred_login, preferred_password
    end

  end
end

