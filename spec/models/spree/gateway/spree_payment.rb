require 'spec_helper'

describe Spree::Payment, type: :model do
  let(:order) { create :order }
  let(:gateway) { Spree::Gateway::AlphaCardGateway.new }
  let(:card) { create :credit_card }

  let(:payment) do
    payment = Spree::Payment.new
    payment.source = card
    payment.order = order
    payment.payment_method = gateway
    payment.amount = 5
    payment
  end

  describe "#purchase!" do
    it 'purchases successfully' do
      VCR.use_cassette("payment/purchase") do
        payment.purchase!
      end

      expect(payment.state).to eq "completed"
    end
  end

  describe "#void_transaction!" do
    it 'voids successfully' do
      response = VCR.use_cassette("payment/void") do
        payment.purchase!
        payment.void_transaction!
      end

      expect(payment.state).to eq "void"
    end
  end
end
