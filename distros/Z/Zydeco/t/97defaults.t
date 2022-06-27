use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	
	class Foo {
		field foo = 666;
		param bar(type => Num) = 999;
		param {'baz'} = 42;
	}
}

my $foo = MyApp->new_foo( foo => 88 );
is($foo->foo, 666);
is($foo->bar, 999);
is($foo->baz, 42);

done_testing;
