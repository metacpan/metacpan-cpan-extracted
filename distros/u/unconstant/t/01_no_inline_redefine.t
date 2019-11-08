use unconstant;
use Test::More tests => 5;

package Foo {
	use constant BAR => 7;
	sub baz { BAR }
}

BEGIN {
	is( Foo::baz, 7, 'Constant set right initially' );
}

BEGIN {
	*Foo::BAR = sub { 42 };
	is( Foo::baz, 42, 'Constant override: sub assign to glob wo/ prototype' );
}

BEGIN {
	no warnings 'redefine';
	*Foo::BAR = sub () { 0 };
	is( Foo::baz, 0, 'Constant override: sub assign to glob w/ prototype' );
}

BEGIN {
	use constant "Foo::BAR" => 9;
	is( Foo::baz, 9, 'Constant override: use constant <string>' );
}

BEGIN {
	use constant *Foo::BAR => 11;
	is( Foo::baz, 11, 'Constant override: use constant <glob>' );
}

1;
