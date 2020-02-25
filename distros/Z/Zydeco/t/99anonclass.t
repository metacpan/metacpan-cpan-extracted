use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp {
	use Zydeco default_is => 'rw';
	
	class Foo {
		type_name Foozle;
	}
	
	class Bar {
		method get_classes () {
			my $k1 = do { class; };

			my $k2 = do { class {
				extends {"::$k1"};
				has foo (type => 'Foozle', required => true);
				class Baz;
			}};
			
			my $k3 = do { class (Int $x) {
				extends {"::$k1"};
				has bar ( type => 'Int', default => $x );
			}};
			
			return ($k1, $k2, $k3);
		}
	}
}

my ($k1, $k2, $k3) = MyApp->new_bar->get_classes;

my $obj1 = $k1->new();

is(
	$k1->FACTORY,
	'MyApp',
);

isnt(
	exception { $k2->new() },
	undef,
);

isnt(
	exception { $k2->new(foo => 42) },
	undef,
);

my $obj2 = $k2->new(foo => MyApp->new_foo);

isa_ok(
	$obj2,
	$k1,
);

can_ok(
	$k3,
	'generate_package',
);

isnt(
	exception { $k3->generate_package("foo") },
	undef,
);

my $k4 = $k3->generate_package(666);

my $obj4 = $k4->new;
is($obj4->bar, 666);
is($obj4->FACTORY, 'MyApp');
is($obj4->GENERATOR, $k3);

my $baz = MyApp->new_baz;

ok(
	!$baz->isa($k2),
);

done_testing;