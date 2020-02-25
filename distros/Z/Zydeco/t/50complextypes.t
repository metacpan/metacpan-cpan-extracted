use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Zydeco factory_package => 'Local';

class Foo;

class Bar {
	method bar (
		# Integer or complex thingy
		Int | ArrayRef[Str|HashRef[~Int]]
		$baz     # ... called $baz
		= 999    # defaults to 999
	) {
		1;
	}
	
	method baz ( Ints $z ) {
		return $z;
	}
	
	begin {
		my $t = Type::Registry->for_class($package);
		$t->add_type(ArrayRef[Int] => 'Ints');
	}
}

my $bar = Local->new_bar;

ok( $bar->bar( 1 ) );

ok( $bar->bar( [qw/ x y z /] ) );

ok( $bar->bar( [qw/ x y z /, {}] ) );

ok( $bar->bar( [qw/ x y z /, { quux => 'quuux' }] ) );

ok( $bar->bar( [qw/ x y z /, { quux => \1 }] ) );

isnt( 
	exception { $bar->bar( [qw/ x y z /, { quux => 42 }] ) },
	undef,
);

is_deeply( $bar->baz([1,2,3]), [1,2,3] );

isnt( 
	exception { $bar->baz(2) },
	undef,
);

done_testing;
