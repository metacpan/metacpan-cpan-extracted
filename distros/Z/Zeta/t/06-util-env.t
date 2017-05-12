use Test::More;

BEGIN {
	use strict;
	use warnings;
    use_ok( 'Zeta::Util', ':ENV' ) || BAIL_OUT('Failed to use Zeta::Util with :ENV');
}

ok(! is_mod_perl(), "Not running under mod_perl");

# We're done here!
done_testing();

