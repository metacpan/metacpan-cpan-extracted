use strict;
use warnings;

use Test::Most tests => 7;

use Test::Mockingbird;

cmp_ok MyClass::do_something('arg0'), 'eq', 'done something',
	'routine is called before being spied on';

my $spy = Test::Mockingbird::spy('MyClass', 'do_something');
MyClass::do_something('arg1');
cmp_ok MyClass::do_something('arg2', 'arg3'), 'eq', 'done something',
	'routine is called while being spied on';

my @calls = $spy->();

# Dump call records only when TEST_VERBOSE is set; lazy-load Data::Dumper
if ($ENV{TEST_VERBOSE}) {
	require Data::Dumper;
	diag Data::Dumper::Dumper(\@calls);
}

is scalar @calls, 2, 'captured two calls';
is_deeply $calls[0], [ 'MyClass::do_something', 'arg1' ],
	'first call arguments correct';
is_deeply $calls[1], [ 'MyClass::do_something', 'arg2', 'arg3' ],
	'second call arguments correct';

Test::Mockingbird::restore_all();

cmp_ok MyClass::do_something('arg4'), 'eq', 'done something',
	'routine called normally after spy removed';
is scalar @calls, 2, 'call list frozen after restore';

package MyClass;

sub do_something { 'done something' }

1;
