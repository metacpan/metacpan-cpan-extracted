use strict;
use warnings;
use Test::Tester tests => 7;
use Test::More;
use Test::Method;

{
	package Test;

	sub new {
		my $class = shift;
		return bless {}, $class;
	}

	sub method {
		my ( $self, $args ) = @_;
		return $args;
	}
}

my $obj = Test->new;

check_test(
	sub {
		method_ok( $obj, 'method', ['foo'], 'foo' );
	},
	{
		ok   => 1,
		name => q[Test->method("foo") is "foo"],
		diag => '',
	},
	'method_ok'
);
