#!perl -w

use strict;
use Test::More tests => 12;

use warnings::method;

our $nwarns;

BEGIN{
	my $msg_re = qr/Method \s+ \S+ \s+ called \s+ as \s+ a \s+ function/xms;

	$SIG{__WARN__} = sub{
		my $msg = join '', @_;

#		diag $msg;

		if($msg =~ /$msg_re/xms){
			$nwarns++;
			return;
		}

		warn $msg;
	};
}

is $nwarns, 3, 'warned in compile time';

{
	package A;
	sub foo :method{
		'foo';
	}
	sub bar {
		'bar';
	}
}

{
	use warnings 'syntax';

	is(A::foo(), 'foo', 'A::foo() called as a function (nwarns++)');
	is(A->foo(), 'foo', 'A->foo() called as a method');

	is(A::bar(), 'bar', 'A::bar() called as a function');
	is(A->bar(), 'bar', 'A->bar() called as a method');

}

{
	no warnings 'syntax';

	is(A::foo(), 'foo', 'A::foo() called as a function');
	is(A->foo(), 'foo', 'A->foo() called as a method');

	is(A::bar(), 'bar', 'A::bar() called as a function');
	is(A->bar(), 'bar', 'A->bar() called as a method');
}


is(&A::foo, 'foo', 'under -w (nwarns++)');

is( A->can('foo')->(), 'foo', 'CodeRef->()');

is ref(\&A::foo), 'CODE', 'getref for method (nwarns++)';
