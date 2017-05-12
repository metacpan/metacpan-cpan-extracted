use Test::More tests => 6;

use strict;
use warnings;

BEGIN {
    use_ok( 'Text::Normalize::NACO' );
}

Text::Normalize::NACO->import( 'naco_normalize' );

my $naco = Text::Normalize::NACO->new;
isa_ok( $naco, 'Text::Normalize::NACO' );

my $original = ' abc ';

is( naco_normalize( $original ),   'ABC', 'naco_normalize()' );
is( $naco->normalize( $original ), 'ABC', 'normalize()' );

$original = ' ABC ';

$naco->case( 'lower' );

is( $naco->normalize( $original ), 'abc', 'normalize()' );
is( naco_normalize( $original, { case => 'lower' } ),
    'abc', 'naco_normalize()' );

