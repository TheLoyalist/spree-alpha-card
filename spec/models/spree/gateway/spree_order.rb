require 'spec_helper'

describe Spree::Order, type: :model do
  let(:card) { create :credit_card }
  let(:order) { create(:completed_order_with_totals) }
  let(:gateway) { Spree::Gateway::AlphaCardGateway.new }
  let!(:payment) do
    payment = Spree::Payment.new
    payment.source = card
    payment.order = order
    payment.payment_method = gateway
    payment.amount = order.total
    payment.state = "completed"
    payment
  end

  describe '#cancel' do
    it 'cancels the order successfully' do
      VCR.use_cassette("order/cancel") do
        order.cancel
      end
      expect(order.state).to eq "canceled"
    end
  end
end
