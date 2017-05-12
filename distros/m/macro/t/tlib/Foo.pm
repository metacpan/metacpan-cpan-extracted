package
	Foo;

use strict;
use warnings;

{
	use macro
		_f => sub { __PACKAGE__ . '::f' },
		_g => sub { __PACKAGE__ . '::g' },
	;


	sub f{
		return _f();
	}

	sub g{
		return _g();
	}
}

sub _g{
	return 'func';
}

sub h{
	return _g();
}

sub line{
	return __LINE__;
}

sub correct_line{
	return 32;
}

1;