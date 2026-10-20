package OrderManagement::Fixtures::InventoryRecords;

use strict;
use warnings;
use OrderManagement::Store;

sub new { bless { store => OrderManagement::Store->new }, $_[0] }

sub table { }

sub query {
  my ($self) = @_;
  return [ map {
    my $row = $_;
    [ map { [$_, defined($row->{$_}) ? $row->{$_} : ''] }
      ('sku', 'product', 'unit price', 'on hand', 'reserved', 'available') ]
  } @{$self->{store}->inventory_rows} ];
}

1;
