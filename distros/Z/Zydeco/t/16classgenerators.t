use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp {
	use Zydeco;
	BEGIN {
		our $VERSION    = '1.0';
		our $AUTHORITY  = 'cpan:TOBYINK';
	};
	class Animal {
		version 1.1;
		has name;
	}
	class Doggo 2.0 {
		extends Species('dog', 'Canis familiaris');
	}
	class Species (Str $common, Str $binomial) {
		extends Animal;
		constant common_name = $common;
		constant binomial    = $binomial;
	}
}

use Types::Standard -types;
use MyApp::Types -types;

my $Human = MyApp::Species->generate_package('human', 'Homo sapiens');

is($MyApp::Animal::VERSION, '1.1');
is($MyApp::Doggo::VERSION, '2.0');

ok(
	ClassName->check($Human) && $Human->can('new'),
	'$Human appears to be a class',
);

ok(
	$Human->binomial eq "Homo sapiens",
	'$Human->binomial eq "Homo sapiens"'
);

ok(
	SpeciesClass->check($Human),
	'$Human passes SpeciesClass',
);

ok(
	!SpeciesInstance->check($Human),
	'$Human fails SpeciesInstance',
);

my $alice = $Human->new(name => 'Alice');

ok(
	$alice->isa($Human),
	'$alice isa $Human',
);

ok(
	$alice->binomial eq "Homo sapiens",
	'$alice->binomial eq "Homo sapiens"'
);

ok(
	$alice->isa('MyApp::Animal'),
	'$alice isa Animal',
);

ok(
	!$alice->isa('MyApp::Species'),
	'NOT $alice isa Species',
);

ok(
	!SpeciesClass->check($alice),
	'$alice fails SpeciesClass',
);

ok(
	SpeciesInstance->check($alice),
	'$alice passes SpeciesInstance',
);

my $lassie = MyApp->new_doggo(name => 'Lassie');

ok(
	SpeciesClass->check('MyApp::Doggo'),
	'MyApp::Doggo passes SpeciesClass',
);

ok(
	SpeciesInstance->check($lassie),
	'$lassie passes SpeciesInstance',
);

package MyApp2 {
	use Zydeco;
	our $XYZZY;
	class Bumph () {
		has xyzzy ( default => $XYZZY );
	}
}

$MyApp2::XYZZY = 42;
my $k1 = MyApp2->generate_bumph;

$MyApp2::XYZZY = 666;
my $k2 = MyApp2->generate_bumph;

isnt(
	exception { MyApp2->generate_bumph(5) },
	undef,
);

is($k1->new->xyzzy, 42);
is($k2->new->xyzzy, 666);

done_testing;