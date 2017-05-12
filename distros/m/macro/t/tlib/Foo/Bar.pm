package
	Foo::Bar;

use strict;
use warnings;

use macro _f => sub { __PACKAGE__ . '::f' };


sub f{
	return _f();
}

{
	sub g_before_defmacro{
		return _g();
	}
	use macro _g => sub { __PACKAGE__ . '::g' };

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
	return 33;
}

1;