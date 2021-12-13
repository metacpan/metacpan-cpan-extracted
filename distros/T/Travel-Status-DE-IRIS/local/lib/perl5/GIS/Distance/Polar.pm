package GIS::Distance::Polar;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

use Math::Trig qw( deg2rad pi );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub _distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;

    $lon1 = deg2rad($lon1);
    $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2);
    $lat2 = deg2rad($lat2);

    my $a = pi/2 - $lat1;
    my $b = pi/2 - $lat2;
    my $c = sqrt( $a ** 2 + $b ** 2 - 2 * $a * $b * cos($lon2 - $lon1) );

    return $KILOMETER_RHO * $c;
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Polar - Polar coordinate flat-earth distance calculations.

=head1 DESCRIPTION

Supposedly this is a formula to better calculate distances at the
poles.

While implemented, this formula has not been tested much.  If you use it
PLEASE share your results with the author.  I've tested the results of this
formula versus L<GIS::Distance::Vincenty> and it appears that this formula
is broken (or the implementation is) as you can see in C<t/polar.t>.

A faster (XS) version of this formula is available as
L<GIS::Distance::Fast::Polar>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

    a = pi/2 - lat1
    b = pi/2 - lat2
    c = sqrt( a^2 + b^2 - 2 * a * b * cos(lon2 - lon1) )
    d = R * c

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

