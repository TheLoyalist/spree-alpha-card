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
      opts = {
        type: 'sale',
        email: options[:email],
        orderid: options[:order_id],
        ipaddress: options[:ip],
      }
      add_money! opts, money, options
      add_credit_card! opts, credit_card

      request opts, 'purchase'
    end



    def credit money, reference, options = {}
      opts = {type: 'credit'}
      add_money! opts, money, currency: options[:originator].payment.currency
      opts[:transactionid] = reference

      request opts, 'credit'
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

    def request opts, originator
      begin
        res = provider.request opts, account
        ActiveMerchant::Billing::Response.new res.success?, "AlphaCardGateway##{originator}: #{res.text}", res.data, response_params(res.data)
      rescue ::AlphaCard::AlphaCardError => e
        ActiveMerchant::Billing::Response.new false, "AlphaCardGateway##{originator}: #{e.message}", e.response.data, response_params(e.response.data)
      end
    end

    def response_params data
      options = {
        test: test?,
        authorization: data['authcode'].presence,
        avs_result: data['avsresponse'].presence,
        cvv_result: data['cvvresponse'].presence,
      }

      unless data['response_code'] == '100'
        options[:error_code] = data['response_code']
      end

      options
    end


    def account
      @account ||= ::AlphaCard::Account.new preferred_login, preferred_password
    end

  end
end

