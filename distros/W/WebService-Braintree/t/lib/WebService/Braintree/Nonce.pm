package WebService::Braintree::Nonce;

sub transactable {
  "fake-valid-nonce";
}

sub consumed {
  "fake-consumed-nonce";
}

sub paypal_one_time_payment {
  "fake-paypal-one-time-nonce";
}

sub paypal_future_payment {
  "fake-paypal-future-nonce";
}

sub apple_pay_visa {
  "fake-apple-pay-visa-nonce";
}

sub apple_pay_amex {
  "fake-apple-pay-amex-nonce";
}

sub apple_pay_mastercard {
  "fake-apple-pay-mastercard-nonce";
}

1;
