use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp {
	use Zydeco;
	class Foo {
		has foo;
		Zydeco::PACKAGE_SPEC->{has}{foo}{type} = Int;
	}
}

like(
	exception { MyApp->new_foo( foo => 1.1 ) },
	qr/did not pass type constraint "Int"/,
);

done_testing;

