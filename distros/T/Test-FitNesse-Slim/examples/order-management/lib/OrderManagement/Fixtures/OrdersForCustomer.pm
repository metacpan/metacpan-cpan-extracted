package OrderManagement::Fixtures::OrdersForCustomer;

use strict;
use warnings;
use OrderManagement::Pricing;
use OrderManagement::Store;

sub slim_constructor_signature { { parameters => ['String'] } }
sub new { bless { store => OrderManagement::Store->new, customer_id => $_[1] }, $_[0] }
sub table { }

sub query {
  my ($self) = @_;
  return [ map {
    my $order = $_;
    [
      ['order id', $order->{id}],
      ['customer', $order->{customer_id}],
      ['status', $order->{status}],
      ['total', OrderManagement::Pricing->from_cents($order->{total_cents})],
    ]
  } @{$self->{store}->orders_for_customer($self->{customer_id})} ];
}

1;
