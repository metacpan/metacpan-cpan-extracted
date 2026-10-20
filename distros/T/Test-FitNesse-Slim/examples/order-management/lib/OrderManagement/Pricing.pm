package OrderManagement::Pricing;

use strict;
use warnings;

sub quote {
  my ($class, $tier, $subtotal) = @_;
  die 'Subtotal must be a non-negative whole number of cents'
    unless defined($subtotal) && $subtotal =~ /\A\d+\z/;

  my $discount = $tier eq 'preferred' && $subtotal >= 2_000
    ? int($subtotal / 10) : 0;
  my $after_discount = $subtotal - $discount;
  my $shipping = $after_discount >= 5_000 ? 0 : 500;

  return {
    subtotal_cents => 0 + $subtotal,
    discount_cents => $discount,
    shipping_cents => $shipping,
    total_cents => $after_discount + $shipping,
  };
}

sub to_cents {
  my ($class, $amount) = @_;
  die 'Amount must use decimal notation with at most two fractional digits'
    unless defined($amount) && $amount =~ /\A(\d+)(?:\.(\d{1,2}))?\z/;
  my ($whole, $fraction) = ($1, $2 // '');
  $fraction .= '0' if length($fraction) == 1;
  return $whole * 100 + ($fraction || 0);
}

sub from_cents {
  my ($class, $cents) = @_;
  die 'Amount must be a non-negative whole number of cents'
    unless defined($cents) && $cents =~ /\A\d+\z/;
  return sprintf '%d.%02d', int($cents / 100), $cents % 100;
}

1;
