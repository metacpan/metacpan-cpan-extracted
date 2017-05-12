# Test::NoXS tests
use strict;

use Test::More;

plan tests => 4;

require_ok('Test::NoXS');

# Scalar::Util actually bootstraps List::Util
eval "use Test::NoXS ':all'";

is( $@, q{}, "told Test::NoXS not to load any XS" );

my $use_F = "use Fcntl qw( LOCK_EX )";

eval $use_F;

ok( $@, "'$use_F' threw an error" );

like( $@, '/XS disabled/', "error matched 'XS disabled'" );

