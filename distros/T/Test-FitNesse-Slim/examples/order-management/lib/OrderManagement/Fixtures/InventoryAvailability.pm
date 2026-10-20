package OrderManagement::Fixtures::InventoryAvailability;

use strict;
use warnings;
use OrderManagement::Store;

sub new { bless { store => OrderManagement::Store->new, sku => '', quantity => 0 }, $_[0] }

sub slim_method_signature {
  my ($self, $method) = @_;
  return { parameters => ['String'] } if $method eq 'set_sku';
  return { parameters => ['Integer'] } if $method eq 'set_quantity_requested';
  return { parameters => [], return => 'Boolean' } if $method eq 'enough_stock';
  return;
}

sub set_sku { $_[0]{sku} = $_[1] }
sub set_quantity_requested { $_[0]{quantity} = $_[1] }
sub table { }
sub begin_table { }
sub reset { }
sub execute { }
sub end_table { }
sub enough_stock {
  my ($self) = @_;
  my $available = $self->{store}->available($self->{sku});
  return defined($available) && $self->{quantity} > 0 && $self->{quantity} <= $available ? 1 : 0;
}

1;
