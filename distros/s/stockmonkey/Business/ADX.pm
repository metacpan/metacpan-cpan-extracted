package Math::Business::ADX;

use strict;
use warnings;
use Carp;

use base 'Math::Business::DMI';

1;

sub set_days {
    my $this = shift;

    $this->SUPER::set_days(@_);
    $this->{tag} = "ADX($this->{days})";
}

__END__

=encoding utf-8

=head1 NAME

Math::Business::ADX - Technical Analysis: ADX (wilder's DMI)

=head1 SYNOPSIS

  use Math::Business::ADx;

  my $adx = new Math::Business::ADX;
     $adx->set_days(14);

  # alternatively/equivilently
  my $adx = new Math::Business::ADX(14);

  # or to just get the recommended model ... (14)
  my $adx = Math::Business::ADX->recommended;

  my @data_points = (
      [ 5, 3, 4 ], # high, low, close
      [ 6, 4, 5 ],
      [ 5, 4, 4.5 ],
  );

  # choose one:
  $adx->insert( @data_points );
  $adx->insert( $_ ) for @data_points;

  my $adx = $adx->query;     # ADX
  my $pdi = $adx->query_pdi; # +DI
  my $mdi = $adx->query_mdi; # -DI

  # or
  my ($pdi, $mdi, $adx) = $adx->query;

  if( defined $adx ) {
      print "ADX: $adi.\n";

  } else {
      print "ADX: n/a.\n";
  }

=head1 SEE ALSO

ADX is an alternate name for DMI.  This module is simply an alias for the DMI.

perl(1), L<Math::Business::DMI>

=cut
