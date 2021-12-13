package GIS::Distance::MathTrig;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

use Math::Trig qw( great_circle_distance deg2rad );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub _distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;

    return great_circle_distance(
        deg2rad($lon1),
        deg2rad(90 - $lat1),
        deg2rad($lon2),
        deg2rad(90 - $lat2),
        $KILOMETER_RHO,
    );
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::MathTrig - Great cirlce distance calculations using Math::Trig.

=head1 DESCRIPTION

This formula uses L<Math::Trig>'s C<great_circle_distance()> which
at this time uses math almost exactly the same formula as the
L<GIS::Distance::Cosine> formula.  And the Cosine formula is about 5%
faster than this formula.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

    lat0 = 90 degrees - phi0
    lat1 = 90 degrees - phi1
    d = R * arccos(cos(lat0) * cos(lat1) * cos(lon1 - lon01) + sin(lat0) * sin(lat1))

As stated in the L<Math::Trig> documentation.

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

