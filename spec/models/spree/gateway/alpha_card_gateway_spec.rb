require 'spec_helper'


RSpec.describe Spree::Gateway::AlphaCardGateway do

  let(:provider) { described_class.new }

  let(:cc) do
    cc = double('credit_card')
    allow(cc).to receive(:year).and_return("2015")
    allow(cc).to receive(:month).and_return("7")
    allow(cc).to receive(:number).and_return("4" + "1"*15)
    cc
  end


  context 'basics' do

    it 'uses itself as provider class' do
      expect(provider).to be_an_instance_of(described_class)
    end

  end

  context '#spree_money_to_alpha_card' do

    it 'formats cents correctly' do
      expect(provider.send :spree_money_to_alpha_card, 254_67).to eq("254.67")
      expect(provider.send :spree_money_to_alpha_card, 99).to eq("0.99")
      expect(provider.send :spree_money_to_alpha_card, 6).to eq("0.06")
      expect(provider.send :spree_money_to_alpha_card, 199_06).to eq("199.06")
    end

  end


  context '#add_credit_card!' do

    it 'sets the date correctly' do
      o = {}
      provider.send :add_credit_card!, o, cc
      expect(o).to include(ccexp: "0715")
    end

    it 'returns the card number' do
      o = {}
      provider.send :add_credit_card!, o, cc
      expect(o).to include(ccnumber: '4111111111111111')
    end

  end


  context 'api calls' do

    before :each do
      provider.set_preference :login, "demo"
      provider.set_preference :password, "password"
    end

    context '#purchase' do

      it 'purchases successfully' do
        opts = {
          email: "l@larskluge.com",
          order_id: "12345678",
          ipaddress: "::1",
          currency: "USD",
        }
        response = VCR.use_cassette("simple purchase") do
          provider.purchase 256_67, cc, opts
        end

        expect(response).to be_an_instance_of(::ActiveMerchant::Billing::Response)
        expect(response).to be_success
        expect(response.params).to include("type" => "sale")
        expect(response.authorization).to eq("123456")
      end

    end

    context '#credit' do

      it 'credits fails b/c alpha card test endpoint does not provide a valid transaction id for testing' do
        payment = double("Spree::Payment", currency: "USD")
        refund = double("Spree::Refund", payment: payment)
        opts = {originator: refund}

        response = VCR.use_cassette('credit without valid transaction id') do
          provider.credit 67_99, "123456", opts
        end

        expect(response).to be_an_instance_of(::ActiveMerchant::Billing::Response)
        expect(response).to_not be_success
        expect(response.message).to match(/transaction not found/i)
      end

    end

  end

end

