package OrderManagement::Fixtures::CustomerEligibility;

use strict;
use warnings;
use OrderManagement::Store;

sub new { bless { store => OrderManagement::Store->new, customer_id => '' }, $_[0] }

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['String'] } if $method eq 'set_customer_id';
  return { parameters => [], return => 'Boolean' } if $method eq 'eligible';
  return;
}

sub set_customer_id { $_[0]{customer_id} = $_[1] }
sub eligible { $_[0]{store}->customer_eligible($_[0]{customer_id}) }
sub table { }
sub begin_table { }
sub reset { }
sub execute { }
sub end_table { }

1;
