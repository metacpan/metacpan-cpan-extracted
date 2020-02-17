use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp {
	use Zydeco;
	
	class Foo {
		my $Rounded = Int->plus_coercions(Num, q{int($_)});
		
		method foo :optimize ( {$Rounded} $x ) {
			return [ __PACKAGE__, $x ];
		}
		
		method bar ( {$Rounded} $y ) {
			method ( {$Rounded} $x ) {
				return [ __PACKAGE__, $x, $y ];
			}
		}
	}
}

my $foo = MyApp->new_foo;

is_deeply(
	$foo->foo(2.1),
	[ 'MyApp', 2 ],
);

isnt(
	exception { $foo->foo("foo") },
	undef,
);

my $bar = $foo->bar(3.1);
is(
	ref($bar),
	'CODE',
);

is_deeply(
	$foo->$bar(4.1),
	[ 'MyApp', 4, 3 ],
);

done_testing;
