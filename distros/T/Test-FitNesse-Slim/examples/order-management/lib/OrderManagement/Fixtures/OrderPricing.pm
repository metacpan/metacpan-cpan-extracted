package OrderManagement::Fixtures::OrderPricing;

use strict;
use warnings;
use OrderManagement::Pricing;

sub new { bless { tier => 'standard', subtotal_cents => 0 }, $_[0] }

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['String'] } if $method eq 'set_customer_tier';
  return { parameters => ['String'] } if $method eq 'set_merchandise_subtotal';
  return { parameters => [], return => 'String' } if $method =~ /\A(?:discount|shipping|total)_amount\z/;
  return;
}

sub set_customer_tier { $_[0]{tier} = $_[1] }
sub set_merchandise_subtotal {
  $_[0]{subtotal_cents} = OrderManagement::Pricing->to_cents($_[1]);
}
sub table { }
sub begin_table { }
sub reset { }
sub execute { }
sub end_table { }
sub _quote { OrderManagement::Pricing->quote($_[0]{tier}, $_[0]{subtotal_cents}) }
sub discount_amount { OrderManagement::Pricing->from_cents($_[0]->_quote->{discount_cents}) }
sub shipping_amount { OrderManagement::Pricing->from_cents($_[0]->_quote->{shipping_cents}) }
sub total_amount { OrderManagement::Pricing->from_cents($_[0]->_quote->{total_cents}) }

1;
