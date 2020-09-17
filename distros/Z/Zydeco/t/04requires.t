use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Devel::StrictMode 'STRICT';

package MyApp {
	use Zydeco;
	role Foo {
		requires bar (Str $x, Num $y);
		requires baz;
	}
}

ok !eval q{
	package Local::Class1;
	use Moo;
	with 'MyApp::Foo';
	1;
};

ok !eval q{
	package Local::Class2;
	use Moo;
	with 'MyApp::Foo';
	sub baz { 42 }
	1;
};

ok eval q{
	package Local::Class3;
	use Moo;
	with 'MyApp::Foo';
	sub bar { 24 }
	sub baz { 42 }
	1;
};

my ($Role, $Class);
package MyApp2 {
	use Zydeco;
	$Role = do { role {
		requires xyzzy(Int $x);
	}};
	$Class = do { class {
		with {$Role};
		method xyzzy { return $_[1] }
	}};
}

if (STRICT) {
	is( $Class->new->xyzzy(4), 4 );
	isnt( exception { $Class->new->xyzzy(1.1) }, undef );
}

else {
	is( $Class->new->xyzzy(4), 4 );
	is( $Class->new->xyzzy(1.1), 1.1 );
}

done_testing;

