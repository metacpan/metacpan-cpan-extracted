#!perl

use Test::More;

BEGIN {
    use_ok( 'Zeta::Util', ':BOOL' ) || BAIL_OUT('Failed to use Zeta::Util with :BOOL');
}

# Check for TRUE / FALSE
ok(TRUE, "Constant for TRUE is valid");
ok(!FALSE, "Constant for FALSE is valid");

# We're done here!
done_testing();