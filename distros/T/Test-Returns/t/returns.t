use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Test::Returns') }

returns_is(5, { type => 'integer' }, 'Integer ok');
returns_ok([], { type => 'arrayref' }, 'Arrayref ok');
returns_ok({ foo => 1 }, { type => 'hashref' }, 'Hashref ok');
returns_isnt('nope', { type => 'hashref' }, 'Fails: not a hashref');

returns_ok(42, { type => 'integer' }, 'Integer is valid');
returns_not_ok('forty', { type => 'integer' }, 'String is not integer');

returns_is([1,2], { type => 'arrayref' }, 'Arrayref matches');
returns_isnt('nope', { type => 'hashref' }, 'String is not hashref');

returns_isnt('abc', { type => 'integer' }, 'String should not match integer');

# type => 'array' is a synonym for 'arrayref' — Params::Validate::Strict only
# understands arrayref; the caller captures list returns as an arrayref.
my @raw = ('abuse@example.com', 'noc@example.com');
returns_ok(\@raw, { type => 'array' }, 'Arrayref accepted as type array');

# Meta-keys from App::Test::Generator schema specs are ignored by the validator.
my $output = {
	_error_handling => { type => 'string' },
	_error_return   => undef,
	type            => 'array',
};
returns_ok(\@raw, $output, 'Array with generator meta-keys validates');

returns_not_ok('not an array', { type => 'array' }, 'String rejected as type array');
returns_not_ok(42,            { type => 'array' }, 'Integer rejected as type array');

done_testing();
