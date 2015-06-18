# spree-alpha-card

An Alpha Card Payment Gateway for [Spree](https://spreecommerce.com/). 


## Installation

Add the gem to your `Gemfile`: 

```ruby
    gem 'spree-alpha-card'
```

Then run `bundle` & (re-)start your Rails application. 


## Configuration

Navigate to your _Spree Administration_ area, then click on _Configurations_, then _Payment Methods_. To add Alpha Card, click on _New Payment Method_, select _Spree::Gateway::AlphaCardGateway_ & give it a display _name_, e.g. "Alpha Card". Click _Create_. 

Now enter your credentials for Alpha Card in the fields _Login_ & _Password_. Click _Update_ & test your new payment method. 


## Tests

To run the test suite, you have to have a Rails app with Spree installed. To do so, run the rake task: 

    # only once
    rake test_app

Run the test suite with: 

    rspec

