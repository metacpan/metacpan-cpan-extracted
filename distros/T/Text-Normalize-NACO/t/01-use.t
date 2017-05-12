use Test::More tests => 2;

use strict;
use warnings;

BEGIN {
    use_ok( 'Text::Normalize::NACO' );
}

my $naco = Text::Normalize::NACO->new;
isa_ok( $naco, 'Text::Normalize::NACO' );
