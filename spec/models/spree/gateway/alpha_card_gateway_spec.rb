require 'spec_helper'


RSpec.describe Spree::Gateway::AlphaCardGateway do

  context 'basics' do

    let(:ac) { described_class.new }

    it 'uses itself as provider class' do
      expect(ac).to be_an_instance_of(described_class)
    end

  end

end

