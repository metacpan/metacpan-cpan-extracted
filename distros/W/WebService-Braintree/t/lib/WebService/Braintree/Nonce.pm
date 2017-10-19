# vim: sw=4 ts=4 ft=perl

package WebService::Braintree::Nonce;

use 5.010_001;
use strictures 1;

# XXX Why aren't these constants like WebService::Braintree::SandboxValues::CreditCardNumber?
sub transactable {
  'fake-valid-nonce';
}

sub consumed {
  'fake-consumed-nonce';
}

sub paypal_one_time_payment {
  'fake-paypal-one-time-nonce';
}

sub paypal_future_payment {
  'fake-paypal-future-nonce';
}

sub apple_pay_visa {
  'fake-apple-pay-visa-nonce';
}

sub apple_pay_amex {
  'fake-apple-pay-amex-nonce';
}

sub apple_pay_mastercard {
  'fake-apple-pay-mastercard-nonce';
}

1;
__END__
