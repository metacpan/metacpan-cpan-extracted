#!/usr/bin/perl

use strict;
use warnings;

my $package = 'Test::MockObject';
use Test::More tests => 103;
use_ok( $package );

# new()
can_ok( $package, 'new' );
my $mock = Test::MockObject->new();
isa_ok( $mock, $package );

# mock()
can_ok( $mock, 'mock' );
my $result = $mock->mock('foo');
can_ok( $mock, 'foo' );
is( $result, $mock, 'mock() should return itself' );
is( $mock->foo(), undef, '... default mock should return nothing' );

# remove()
can_ok( $package, 'remove' );
$result = $mock->remove('foo');
ok( ! $mock->can('foo'), 'remove() should remove a sub from potential action' );
is( $result, $mock, '... returning itself' );

# this is used for a couple of tests
sub foo { 'foo' }

$mock->mock('foo', \&foo);
local $@;
my $fooput = eval{ $mock->foo() };
is( $@, '', 'mock() should install callable subref' );
is( $fooput, 'foo', '... which behaves normally' );

is( $mock->can('foo'), \&foo, 'can() should return a subref' );

can_ok( $package, 'set_always' );
$result = $mock->set_always( 'bar', 'bar' );
is( $mock->bar(), 'bar', 
	'set_always() should add a sub that always returns its value' );
is( $mock->bar(), 'bar', '... so it should at least do it twice in a row' );
is( $result, $mock, '... returning itself' );

can_ok( $package, 'set_true' );
$result = $mock->set_true( 'blah' );
ok( $mock->blah(),  'set_true() should install a sub that returns true' );
$result = $mock->set_true( qw( true1 true2 true3 ) );
ok( $mock->true1(), '... or multiple subs' );
ok( $mock->true2(), '... all' );
ok( $mock->true3(), '... returning true' );
is( $result, $mock, '... and should return itself' );

can_ok( $package, 'set_false' );
$result = $mock->set_false( 'bloo' );
ok( ! $mock->bloo(),    'set_false() should install a sub that returns false' );
my @false = $mock->bloo();
ok( ! @false,           '... even in list context' );
is( $result, $mock,     '... and should return itself' );

$result = $mock->set_false( qw( false1 false2 false3 ) );
ok( ! $mock->false1(),  '... or multiple subs' );
ok( ! $mock->false2(),  '... all' );
ok( ! $mock->false3(),  '... returning false' );

can_ok( $package, 'set_list' );
$result = $mock->set_list( 'baz', ( 4 .. 6 ) );
is( scalar $mock->baz(), 3, 'set_list() should install a sub to return a list');
is( $result, $mock, '... and should return itself' );
is( join('-', $mock->baz()), '4-5-6',
	'... and the sub should always return the list' );

can_ok( $package, 'set_series' );
$result = $mock->set_series( 'amicae', 'Sunny', 'Kylie', 'Isabella' );
is( $mock->amicae(), 'Sunny',
	'set_series() should install a sub to return a series' );
is( $result, $mock, '... and should return itself' );
is( $mock->amicae(), 'Kylie', '... in order' );
is( $mock->amicae(), 'Isabella', '... through the series' );
ok( ! $mock->amicae(), '... but false when finishing the series' );

can_ok( $package, 'called' );
$mock->foo();
ok( $mock->called('foo'),
	'called() should report true if named sub was called' );
ok( ! $mock->called('notfoo'), '... and false if it was not' );

can_ok( $package, 'clear' );
$result = $mock->clear();
ok( ! $mock->called('foo'),
	'clear() should clear recorded call stack' );
is( $result, $mock, '... and should return itself' );

can_ok( $package, 'call_pos' );
$mock->foo(1, 2, 3);
$mock->bar([ foo ]);
$mock->baz($mock, 88);
is( $mock->call_pos(1), 'foo', 
	'call_pos() should report name of sub called by position' );
is( $mock->call_pos(-1), 'baz', '... and should handle negative numbers' );

can_ok( $package, 'call_args' );
my ($arg) = ($mock->call_args(2))[1];
is( $arg->[0], 'foo',
	'call_args() should return args for sub called by position' );
is( ($mock->call_args(2))[0], $mock,
	'... with the object as the first argument' );

can_ok( $package, 'call_args_string' );
is( $mock->call_args_string(1, '-'), "$mock-1-2-3",
	'call_args_string() should return args joined' );
is( $mock->call_args_string(1), "${mock}123", '... with no default separator' );

can_ok( $package, 'call_args_pos' );
is( $mock->call_args_pos(3, 1), $mock,
	'call_args_argpos() should return argument for sub by position' );
is( $mock->call_args_pos(-1, -1), 88,
	'... handing negative positions equally well' );

can_ok( $package, 'called_ok' );
$mock->called_ok( 'foo' );

can_ok( $package, 'called_pos_ok' );
$mock->called_pos_ok( 1, 'foo' );

can_ok( $package, 'called_args_string_is' );
$mock->called_args_string_is( 1, '-', "$mock-1-2-3" );

can_ok( $package, 'called_args_pos_is' );
$mock->called_args_pos_is( 1, -1, 3 );

can_ok( $package, 'fake_module' );
$mock->fake_module( 'Some::Module' );
is( $INC{'Some/Module.pm'}, 1, 
	'fake_module() should prevent a module from being loaded' );

my @imported;
$mock->fake_module( 'import::me', import => sub { push @imported, $_[0] });
eval { import::me->import() };
is( $imported[0], 'import::me',
	'fake_module() should install functions in new package namespace' );

{
	my $warnings = '';
	local $SIG{__WARN__} = sub { $warnings .= shift };
	$mock->fake_module( 'badimport', foo => 'bar' );
	like( $warnings, qr/'foo' is not a code reference/,
	    '... and should carp if it does not receive a function reference' );
}

can_ok( $package, 'fake_new' );
$mock->fake_new( 'Some::Module' );
is( Some::Module->new(), $mock, 
	'fake_new() should create a fake constructor to return mock object' );

can_ok( $package, 'check_class_loaded' );
ok( $package->check_class_loaded( 'Test::MockObject' ),
	'check_class_loaded() should return true for loaded class' );

ok( ! $package->check_class_loaded( 'Test::MockObject::Bob' ),
	'... and false for unloaded class' );

ok( $package->check_class_loaded( 'strict' ),
	'... true for loaded class with no colons' );

ok( ! $package->check_class_loaded( 'unstrict' ),
	'... false for unloaded class with no colons' );

package Blah;
package Blah::Nested;
package main;

ok( $package->check_class_loaded( 'Blah' ),
	'... true for defined class even with no symbols' );

ok( $package->check_class_loaded( 'Blah::Nested' ),
	'... true for defined class with colons but with no symbols' );

$INC{'Some.pm'}         = 1;
$INC{'Some/Package.pm'} = 1;

ok( $package->check_class_loaded( 'Some' ), '... true for class in %INC' );

ok( $package->check_class_loaded( 'Some::Package' ),
	'... and true for class with colons in %INC' );

can_ok( $package, 'set_bound' );
$arg = 1;
$result = $mock->set_bound( 'bound', \$arg );
is( $mock->bound(), 1, 'set_bound() should bind to a scalar reference' );
is( $result, $mock, '... and should return itself' );
$arg = 2;
is( $mock->bound(), 2, '... and its return value should change with the ref' );
$arg = [ 3, 5, 7 ];
$mock->set_bound( 'bound_array', $arg );
is( join('-', $mock->bound_array()), '3-5-7', '... handling array refs' );
$arg = { foo => 'bar' };
$mock->set_bound( 'bound_hash', $arg );
is( join('-', $mock->bound_hash()), 'foo-bar', '... and hash refs' );

{
	local $INC{'Carp.pm'} = 1;
	local *Carp::carp;

	my @c;
	*Carp::carp = sub {
		push @c, shift;
	};

	$mock->notamethod();
	is( @c, 1, 'Module should carp when calling a non-existant method' );
	is( $c[0], "Un-mocked method 'notamethod()' called", '... warning as such');
}

# next_call()
can_ok( $mock, 'next_call' );
$mock->clear();

$mock->foo( 1, 2, 3 );
$mock->bar();
$mock->baz();

my ($method, $args) = $mock->next_call();
is( $method, 'foo', 'next_call() should return first method' );
isa_ok( $args, 'ARRAY', '... and args in a data structure which' );
is( join('-', @$args), "$mock-1-2-3", '... containing the real arguments' );
ok( ! $mock->called( 'foo' ), '... and removing that call from the stack' );

$result = $mock->next_call( 2 );
is( $result, 'baz',
	'... and should skip multiple calls, with an argument provided' );
is( $mock->next_call(), undef,
	'... returning undef with no call in that position' );
is( $result, 'baz', '... returning only the method name in scalar context' );

# _calls()
can_ok( $package, '_calls' );
my $callstack = Test::MockObject::_calls( 'key' );
isa_ok( $callstack, 'ARRAY', '_calls() should return something that' );
$callstack->[0] = 'foo';
is_deeply( Test::MockObject::_calls( 'key' ), [ 'foo' ],
	'... always for the same key' );

# _subs()
can_ok( $package, '_subs' );
my $subhash = Test::MockObject::_subs( 'key' );
isa_ok( $subhash, 'HASH', '_subs() should return something that' );
$subhash->{foo} = 'bar';
is_deeply( Test::MockObject::_subs( 'key' ), { foo => 'bar' },
	'... always for the same key' );
