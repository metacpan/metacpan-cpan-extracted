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
		method_ok( $obj, 'method', undef, 'false' );
	},
	{
		ok   => 0,
		name => q[Test->method() is "false"],
		diag => 'Compared $data->method'
			. "\n   got : 'true'"
			. "\nexpect : 'false'",
	},
	'method_ok'
);
