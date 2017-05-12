#!perl

use strict;
use warnings;

use Test::More tests => 6;

# enable lexical warnings from module at compile time
BEGIN { use_ok( 'UNIVERSAL::can' ) }

{
	package Foo;

	use vars '$AUTOLOAD';
	use Scalar::Util 'blessed';

	sub new
	{
		my ($class, %args) = @_;

		while (my ($name, $value) = each %args)
		{
			$args{$name} = sub { return $value };		
		}

		bless \%args, $class;
	}

	sub can
	{
		my ($self, $name) = @_;
		return $self->SUPER::can( $name ) unless blessed( $self );
		return $self->{$name} if exists $self->{$name};
		return $self->SUPER::can( $name );
	}

	sub DESTROY {}

	sub AUTOLOAD
	{
		my $self     = shift;
		my ($method) = $AUTOLOAD =~ /::(\w+)$/;
		return unless exists $self->{$method};
		return $self->{$method}->( @_ );
	}
}

my $foo = Foo->new( foo => 'it is foo', bar => 'it is not foo' );

my ($can_foo, $can_baz);

eval { die "Failure\n" };
{
	no warnings 'UNIVERSAL::can';
	$can_foo = UNIVERSAL::can( $foo, 'foo' );
	$can_baz = UNIVERSAL::can( $foo, 'baz' );
}

ok(   defined  $can_foo,
	'UNIVERSAL::can() should return a true value, if possible' );
ok(   defined &$can_foo, '... a code ref, if possible' );
ok( ! defined  $can_baz, '... or undef if not' );

is( $can_foo->(), 'it is foo', '... the proper code ref' );
is( $@, "Failure\n", '... not eating any exceptions already thrown' );
