#! perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::MockObject;

use Scalar::Util 'weaken';

{
	my $mock = Test::MockObject->new();

	local $@ = '';
	eval { $mock->called( 1, 'foo' ) };
	is( $@, '', 'called() should not die from no array ref object' );
}

{
	my $mock = Test::MockObject->new();

	$mock->{_calls} = [ 1 .. 4 ];
	$mock->_call( 5 );
	is( @{ $mock->{_calls} }, 4,
		'_call() should not autovivify extra calls on the stack' );
}

{
	my $mock = Test::MockObject->new();
	my $warn = '';
	local $SIG{__WARN__} = sub {
		$warn = shift;
	};
	$mock->fake_module( 'Foo', bar => sub {} );
	$mock->fake_module( 'Foo', bar => sub {} );
	is( $warn, '', 'fake_module() should catch redefined sub warnings' );
}

{
	my ($ok, $warn, @diag) = ('') x 2;
	{
		local (*Test::Builder::ok, *Test::Builder::diag);
		*Test::Builder::ok = sub {
			$ok = $_[1];
		};

		*Test::Builder::diag = sub {
			push @diag, $_[1];
		};

		my $mock = Test::MockObject->new();
		$mock->{_calls} = [ [ 4, 4 ], [ 5, 5 ] ];

		$mock->called_pos_ok( 2, 8 );

		local $SIG{__WARN__} = sub {
			$warn = shift;
		};

		$mock->called_pos_ok( 888, 'foo' );
	}

	ok( ! $ok, 'called_pos_ok() should return false if name does not match' );
	like( $diag[0], qr/Got.+Expected/s, '... printing a helpful diagnostic' );
	unlike( $warn, qr/uninitialized value/,
		'called_pos_ok() should throw no uninitialized warnings on failure');
	like( $diag[1], qr/'undef'/, '... faking it with the word in the error' );
}

{
	my $mock = Test::MockObject->new();
	$mock->set_true( 'foo' );
	$_ = 'bar';
	$mock->foo( $1 ) if /(\w+)/;
	is( $mock->call_args_pos( -1, 2 ), 'bar', 
		'$1 should be preserved through AUTOLOAD invocation' );
}

{
	my $mock = Test::MockObject->new();
	$mock->fake_module( 'fakemodule' );
	no strict 'refs';
	ok( %{ 'fakemodule::' },
		'fake_module() should create a symbol table entry for the module' );
}

# respect list context at the end of a series
{
	my $mock = Test::MockObject->new();
	$mock->set_series( count => 2, 3 );
	my $i;
	while (my ($count) = $mock->count())
	{
		$i++;
		last if $i > 2;
	}

	is( $i, 2, 'set_series() should return false at the end of a series' );
}

# Jay Bonci discovered false positives in called_ok() in 0.11
{
	local *Test::Builder::ok;
	*Test::Builder::ok = sub {
		$_[1];
	};

	my $new_mock = Test::MockObject->new();
	my $result   = $new_mock->called_ok( 'foo' );

	is( $result, 0, 'called_ok() should not report false positives' );
}

package Override;

my $id = 'default';

use base 'Test::MockObject';
use overload '""' => sub { return $id };

package main;

my $o = Override->new();
$o->set_always( foo => 'foo' );

is( "$o", 'default',  'default overloadings should work' );
$id = 'my id';
is( "$o", 'my id',    '... and not be static' );
is( $o->foo(), 'foo', '... but should not interfere with method finding' );

# no overload '""';

# David Pisoni found memory leak condition
{
	# Setup MOs with 2 references
	my ($obj1, $obj2, $obj1prime, $obj2prime);
	$obj1 = $obj1prime = Test::MockObject->new();
	$obj2 = $obj2prime = Test::MockObject->new();

	# Weaken one of the references each
	weaken $obj1prime;
	weaken $obj2prime;

	# test for memory leak condition
	$obj1->set_true('this');
	$obj1->this($obj2);

	undef $obj2;

	is( ref($obj2prime), 'Test::MockObject',
		'MO cached by another MO log should not be garbage collected' );
	undef $obj1;

	ok( !ref($obj2prime), '... but should go away when caching MO does' );

	ok( !ref($obj1prime),
		'... and the caching MO better go away too!' );
}

# Mutant reported RT #21049 - lack of new() in fake_module() may be a problem
{
	my $mock = Test::MockObject->new();
	local $@;

	$INC{'Some/Module.pm'} = 1;
	eval { $mock->fake_module( 'Some::Module' ) };
	like( $@, qr/No mocked subs for loaded module 'Some::Module'/,
		'fake_module() should throw exception for loaded module without mocks');
}

# Adam Kennedy reported RT #19448 - typo in check_class_loaded()
{
	my $mock = Test::MockObject->new();

	package Foo::Bar;

	sub foo {}

	package main;

	ok( $mock->check_class_loaded( 'Foo::Bar' ),
		'check_class_loaded() should work for nested class names' );
}
