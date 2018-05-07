use strict;
use warnings;
use feature qw( say );

# Global install
# cpanm -U Acme::Urinal || true && perl -Ilib -Mlazy author-testing/command-line.pl

# Global verbose install
# cpanm -U Acme::Urinal || true && perl -Ilib -Mlazy=-v,--no-color author-testing/command-line.pl

# Local install
# cpanm -U Acme::Urinal || true && rm -rf foo_local && perl -Ilib -Mlocal::lib=foo_local -Mlazy author-testing/command-line.pl

use Acme::Urinal;

my $urinals = Acme::Urinal->new( [ 0 .. 7 ] );

for ( 0 .. 2 ) {
    my ( $index, $resource, $comfort_level ) = $urinals->pick_one;
    say $index;
}
