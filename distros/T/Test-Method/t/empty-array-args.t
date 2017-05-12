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
		return 'true';
	}
}

my $obj = Test->new;

check_test(
	sub {
		method_ok( $obj, 'method', [], 'true' );
	},
	{
		ok   => 1,
		name => q[Test->method() is "true"],
		diag => '',
	},
	'method_ok'
);
