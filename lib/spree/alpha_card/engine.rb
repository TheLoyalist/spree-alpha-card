module Spree
  module AlphaCard
    class Engine < ::Rails::Engine
      engine_name "spree-alpha-card"

      isolate_namespace Spree::AlphaCard

      initializer "spree.spree-alpha-card.payment_methods", :after => "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods << Gateway::AlphaCardGateway
      end
    end
  end
end

