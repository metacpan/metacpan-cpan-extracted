use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp {
	use Zydeco;
	class Foo;
}

package MyApp {
	use Zydeco;
	class Bar {
		has foo (type => Foo);
	}
}

my $foo = MyApp->new_foo;
my $bar = MyApp->new_bar(foo => $foo);

isnt(
	exception { $bar->foo(undef) },
	undef,
);

done_testing;
