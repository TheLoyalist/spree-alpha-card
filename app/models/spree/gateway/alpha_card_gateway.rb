#
# Alpha Card Payment Gateway
#
#
# TODO include shipping address fields
#
# cvv: not provided by Spree?
#
module Spree
  class Gateway::AlphaCardGateway < Gateway

    preference :login, :string, default: 'demo'
    preference :password, :string, default: 'password'


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
      %w(purchase credit)
    end

    def void transaction_id, options = {}
      opts = {
        type: 'void',
        transactionid: transaction_id
      }
      request opts, 'void'
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
      add_bill_address! opts

      request opts, 'purchase'
    end

    def refund money, reference, options = {}
      opts = {
        type: 'refund',
        transactionid: reference
      }
      add_money! opts, money, options

      request opts, 'refund'
    end

    def credit money, reference, options = {}
      refund money, reference, options
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

    def add_bill_address! opts
      order_number, _ = opts[:orderid].split('-')
      order = Spree::Order.find_by number: order_number

      if order
        address = order.bill_address
        opts.merge!(
          firstname: address.firstname,
          lastname:  address.lastname,
          address1:  address.address1,
          address2:  address.address2,
          city:      address.city,
          state:     address.state.abbr,
          zip:       address.zipcode,
          country:   address.country.iso,
          phone:     address.phone,
        )
      end
    end

    def request opts, originator
      begin
        res = provider.request opts, account
        ActiveMerchant::Billing::Response.new res.success?, "AlphaCardGateway##{originator}: #{res.text}", res.data, response_params(res.data)
      rescue ::AlphaCard::AlphaCardError => e
        options = response_params(e.response.data)
        message = "Alpha Card: #{e.message} #{options[:avs_result].try(:message)}".strip
        ActiveMerchant::Billing::Response.new false, message, e.response.data, options
      end
    end

    def response_params data
      options = {
        test: test?,
        authorization: data['authcode'].presence,
        cvv_result: data['cvvresponse'].presence,
      }

      if data['avsresponse'].present?
        options[:avs_result] = ActiveMerchant::Billing::AVSResult.new code: data['avsresponse']
      end

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
