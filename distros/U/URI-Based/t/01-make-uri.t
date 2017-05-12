#!perl -T

use Test::More 0.88;

BEGIN { use_ok('URI::Based'); }

my $uri = URI::Based->new( 'http://angel.net/~nic' );

ok( $uri, 'created URI::Based object' );

is(
	$uri->with( '/path/to/add', param1 => 'some value' )->as_string,
	'http://angel.net/~nic/path/to/add?param1=some+value',
	'adds path and query to base URI'
);

is(
	$uri->with( '/a/different/path', param1 => 'another value', param2 => 'yet another' )->as_string,
	'http://angel.net/~nic/a/different/path?param1=another+value&param2=yet+another',
	'a second path and query replace the first'
);

is(
	$uri->with( '/a/different/path', { one_param => 'value' } )->as_string,
	'http://angel.net/~nic/a/different/path?one_param=value',
	'you can pass in a hashref'
);

done_testing();
