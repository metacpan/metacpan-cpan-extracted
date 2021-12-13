package GIS::Distance::Haversine;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

use Math::Trig qw( deg2rad );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

sub _distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;

    $lon1 = deg2rad($lon1);
    $lat1 = deg2rad($lat1);
    $lon2 = deg2rad($lon2);
    $lat2 = deg2rad($lat2);

    my $dlon = $lon2 - $lon1;
    my $dlat = $lat2 - $lat1;
    my $a = (sin($dlat/2)) ** 2 + cos($lat1) * cos($lat2) * (sin($dlon/2)) ** 2;
    my $c = 2 * atan2(sqrt($a), sqrt(abs(1-$a)));

    return $KILOMETER_RHO * $c;
}

# Eric Samuelson recommended this formula.
# http://forums.devshed.com/t54655/sc3d021a264676b9b440ea7cbe1f775a1.html
# http://williams.best.vwh.net/avform.htm
# It seems to produce the same results at the hsin formula, so...
#
# my $dlon = $lon2 - $lon1;
# my $dlat = $lat2 - $lat1;
# my $a = (sin($dlat / 2)) ** 2
#     + cos($lat1) * cos($lat2) * (sin($dlon / 2)) ** 2;
# $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
#
# Maybe test for speed before tossing?

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Haversine - Exact spherical distance calculations.

=head1 DESCRIPTION

This is the default distance calculation for L<GIS::Distance> as
it keeps a good balance between speed and accuracy.

A faster (XS) version of this formula is available as
L<GIS::Distance::Fast::Haversine>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = (sin(dlat/2))^2 + cos(lat1) * cos(lat2) * (sin(dlon/2))^2
    c = 2 * atan2( sqrt(a), sqrt(1-a) )
    d = R * c

=head1 SEE ALSO

=over

=item *

L<http://mathforum.org/library/drmath/view/51879.html>

=item *

L<http://www.faqs.org/faqs/geography/infosystems-faq/>

=back

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

