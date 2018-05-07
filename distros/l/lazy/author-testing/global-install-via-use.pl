use strict;
use warnings;
use feature qw( say );

=head1 SYNOPSIS

    cpanm -U Acme::Urinal || true && perl -Ilib author-testing/global-install-via-use.pl

=cut

use lazy;

use Acme::Urinal;

my $urinals = Acme::Urinal->new( [ 0 .. 7 ] );

for ( 0 .. 1 ) {
    my ( $index, $resource, $comfort_level ) = $urinals->pick_one;
    say $index;
}
