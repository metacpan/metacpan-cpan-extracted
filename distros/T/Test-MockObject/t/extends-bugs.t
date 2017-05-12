#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 33;
use Test::Exception;

my $module = 'Test::MockObject::Extends';
use_ok( $module ) or exit;

# RT #17692 - cannot mock inline package without new()

{ package InlinePackageNoNew; sub foo; }

lives_ok { Test::MockObject::Extends->new( 'InlinePackageNoNew' ) }
	'Mocking a package defined inline should not load anything';

# RT #15446 - isa() ignores type of blessed reference

# fake that Foo is loaded
$INC{'Foo.pm'} = './Foo.pm';

# create object
my $obj = bless {}, "Foo";

# test if the object is a reference to a hash

# silence warnings with UNIVERSAL::isa and Sub::Uplevel
no warnings 'uninitialized';
ok( $obj->isa( 'HASH' ), 'The object isa HASH' );
ok( UNIVERSAL::isa( $obj, 'HASH' ),
	'...also if UNIVERSAL::isa() is called as a function' );

# wrap in mock object
Test::MockObject::Extends->new( $obj );

# test if the mock object is still a reference to a hash
ok( $obj->isa( 'HASH' ), 'The extended object isa HASH' );
ok( UNIVERSAL::isa( $obj, 'HASH' ),
	"...also if UNIVERSAL::isa() is called as a function" );

# RT #14445 - inherited AUTOLOAD does not work correctly

CLASS:
{
	package Foo;

	use vars qw( $called_foo $called_autoload $method_name );

	BEGIN
	{
		$called_foo      = 0;
		$called_autoload = 0;
		$method_name     = '';
	}

	sub new
	{
		bless {}, $_[0];
	}

	sub foo
	{
		$called_foo++;
		return 'foo';
	}

	sub AUTOLOAD
	{
		$called_autoload++;
		$method_name = $Foo::AUTOLOAD;
		return 'autoload';
	}

	package Bar;

	use vars qw( @ISA $called_this );

	BEGIN
	{
		@ISA         = 'Foo';
		$called_this = 0;
	}

	sub this
	{
		$called_this++;
		return 'this';
	}

	1;
}

my $object = Foo->new();
isa_ok( $object, 'Foo' );

# Create a trvial mocked autoloading object
my $mock = Test::MockObject::Extends->new($object);
isa_ok( $mock, 'Foo' );

# Call foo
is( $mock->foo(),          'foo', 'foo() returns as expected'     );
is( $Foo::called_foo,          1, '$called_foo is incremented'    );
is( $Foo::called_autoload,     0, '$called_autoload is unchanged' );
is( $Foo::method_name,        '', '$method_name is unchanged'     );

# Call an autoloaded method
is( $mock->bar(),          'autoload', 'bad() returns as expected'         );
is( $Foo::called_autoload,          1, '$called_autoload is incremented'   );
is( $Foo::method_name,     'Foo::bar', '$method_name is the correct value' );

$object = Bar->new();
isa_ok( $object, 'Foo' );
isa_ok( $object, 'Bar' );

# Create a non-trivial subclassed autoloading object
$mock = Test::MockObject::Extends->new( $object );
isa_ok( $mock, 'Foo' );
isa_ok( $mock, 'Bar' );

# Call foo
is( $mock->foo(),         'foo', 'foo() returns as expected'     );
is( $Foo::called_foo,         2, '$called_foo is incremented'    );
is( $Foo::called_autoload,    1, '$called_autoload is unchanged' );
is( $Bar::called_this,        0, '$called_this is unchanged'     );

# Call this
is( $mock->this(),         'this', 'this() returns as expected'    );
is( $Foo::called_foo,          2,  '$called_foo is unchanged'      );
is( $Foo::called_autoload,     1,  '$called_autoload is unchanged' );
is( $Bar::called_this,         1,  '$called_this is incremented'   );

# Call an autoloaded method
is( $mock->that(),          'autoload', 'that() returns as expected'      );
is( $Foo::called_autoload,           2, '$called_autoload is incremented' );
is( $Foo::method_name,     'Bar::that', '$method_name is set correctly'   );

### This might demonstrate why the problem happened
is( $Bar::AUTOLOAD, undef,
	"The \$AUTOLOAD for the object's actual class should be unset" );
is( $Foo::AUTOLOAD, 'Bar::that',
    'The $AUTOLOAD that catches the call should contain the desired name'
);

# Get rid of a silly warning
$Bar::AUTOLOAD = $Bar::AUTOLOAD;

package Obj;

sub class_method { 'TRUE-CLASS-METHOD' }

package main;

my $o = Test::MockObject::Extends->new('Obj')->set_always(
	-class_method => 'FAKED RESULT' );
is(  $o->class_method, 'FAKED RESULT', 'class method mocked' );
