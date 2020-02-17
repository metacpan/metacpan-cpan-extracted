use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	class Doggo with Generators::Species('dog', 'Canis familiaris'), GoodBoi?;
	role Generators::Species (Str $common, Str $binomial) {
		constant common_name = $common;
		constant binomial    = $binomial;
	}
}

my $lassie = MyApp->new_doggo(name => 'Lassie');

ok(
	$lassie->does('MyApp::Generators::Species::__GEN000001__'),
	'$lassie->does("MyApp::Generators::Species::__GEN000001__")'
);

ok(
	$lassie->binomial eq "Canis familiaris",
	'$lassie->binomial eq "Canis familiaris"',
);

ok(
	$lassie->does('MyApp::GoodBoi'),
	'$lassie->does("MyApp::GoodBoi")'
);

package MyApp2 {
	use Zydeco;
	role SimpleAttributes ( ArrayRef[Str] @attrs ) {
		for my $attr (@attrs) {
			has {$attr} ( is => ro );
		}
	}
	class Foo {
		with SimpleAttributes(qw( foo bar baz ));
	}
}

my $obj = MyApp2->new_foo( foo => 1, bar => 2, baz => 3 );
is($obj->foo, 1);
is($obj->bar, 2);
is($obj->baz, 3);

my $hmm = q{
	package MyApp3 {
		use Zydeco;
		role Foo (Int $x) {
			class Bar;
		}
	}
};

undef $@;
ok !eval "$hmm; 1";
like($@, qr/Foo is not a class/);

$hmm = q{
	package MyApp4 {
		use Zydeco;
		role Foo {
			class Bar;
		}
	}
};

undef $@;
ok !eval "$hmm; 1";
like($@, qr/Foo is not a class/);

done_testing;