#!perl

use Test::More;

BEGIN {
    use_ok( 'Zeta::Util', 'get_opts' ) || BAIL_OUT('Failed to use Zeta::Util with get_opts');
}

# declare variables
my $result;
my @result;
my %result;

# Check single scalar argument
$result = get_opts(1);
is($result, 1, "Single argument returns as scalar when returning to a scalar");
%result = get_opts(2);
is($result{'arg1'}, 2, "Single argument returns as hash when returning to a hash or array");

# Check single arrayref argument
$result = get_opts([3,4]);
is($result->[1], 4, "Single arrayref argument returns as arrayref to a scalar");
@result = get_opts([5,6]);
is($result[1], 6, "Single arrayref argument returns as array to an array");

# Check single hashref argument
$result = get_opts({ child => 'lordyn' });
is($result->{'child'}, 'lordyn', "Single hashref argument returns as hashref to a scalar");
%result = get_opts( { model => 'S10-3t' });
is($result{'model'}, 'S10-3t', 'Single hashref argument returns as hash to a hash');

# Odd number of arguments
$result = get_opts('a', 'b', 'c');
is($result->[2], 'c', "Odd number of arguments > 1 returns as arrayref to a scalar");
@result = get_opts('ab', 'cd', 'ef');
is($result[1], 'cd', 'Odd number of arguments > 1 returns as array to an array');

# Even number of arguments
$result = get_opts(x => 'the spot', a => 'alpha');
is($result->{'x'}, 'the spot', 'Even number of arguments returns as hashref to a scalar');
%result = get_opts(x => 'the spot', z => 'omega');
is($result{'z'}, 'omega', 'Even number of arguments returns as hash to a hash');

# We're done here!
done_testing();