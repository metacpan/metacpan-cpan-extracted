package OrderManagement::Fixtures::ReplenishmentPriority;

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
      qw(sku product available) ]
  } @{$self->{store}->replenishment_rows} ];
}

1;
