require 'spec_helper'

describe Spree::Refund, type: :model do
  let(:order) { create :order }
  let(:gateway) { Spree::Gateway::AlphaCardGateway.new }
  let(:card) { create :credit_card }
  let(:amount) { 5 }

  let(:payment) do
    payment = Spree::Payment.new
    payment.source = card
    payment.order = order
    payment.payment_method = gateway
    payment.amount = amount
    payment
  end

  let(:refund_reason) { create(:refund_reason) }

  let(:refund) { create(:refund, payment: payment, amount: amount, reason: refund_reason, transaction_id: nil) }

  it 'performs successfully' do
    VCR.use_cassette("refund/perform") do
      payment.purchase!
      refund
    end
  end
end
