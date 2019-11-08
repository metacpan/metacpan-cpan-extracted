use Test::More tests => 6;

package Foo1 {
	use constant BAR => 7;
	sub baz { BAR }
}

BEGIN {
	no warnings 'redefine';
	is( Foo1::baz, 7, 'Constant set right initially' );
	*Foo1::BAR = sub { 42 };
	is( Foo1::baz, 7, 'Constants are inlined' );
}

package Foo2 {
	use unconstant;
	use constant BAR => 7;
	sub baz { BAR }
}

BEGIN {
	no warnings 'redefine';
	is( Foo2::baz, 7, 'Constant set right initially' );
	*Foo2::BAR = sub { 42 };
	is( Foo2::baz, 42, 'Constant not inlined' );
}

package Foo3 {
	use unconstant;
	no unconstant;
	use constant BAR => 7;
	sub baz { BAR }
}

BEGIN {
	no warnings 'redefine';
	is( Foo3::baz, 7, 'Constant set right initially' );
	*Foo3::BAR = sub { 42 };
	is( Foo3::baz, 7, 'Constant are inlined again after use of [no constant]' );
}

1;
