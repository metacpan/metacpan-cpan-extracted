use v5.14;
use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	
	class Animal {
		has name;
		class Mammal {
			class Dog;
			class Cat {
				with Cute?;
			}
			class Primate {
				class Monkey;
				class Gorilla;
				class ::Human {
					has +name ( required => 1 );
					class Superhuman;
					class +Employee {
						has job_title;
						method bleh { return $factory }
					}
				}
			}
		}
		class Fish;
		class Bird {
			has wings;
			class Penguin {
				with Flightless?;
			}
			class Corvid {
				with Evil?;
				class Crow;
				class Magpie;
			}
		}
		class Reptile;
		class Amphibian {
			class Frog;
			class Toad;
		}
		class Invertebrate;
	}
	
	class Rabbit extends Mammal with Cute?, Bouncy?;
	
	role Environment ( Str $env ) {
		method environment { return $env }
	}
	
	class Eagle extends Bird with Environment('sky'), EagleEyed?;
	class Gull extends Bird with Environment('cliffs'), Annoying?;
}

my $superman = MyApp->new_superhuman(name => 'Kal El');

isa_ok($superman, $_, "\$superman") for qw(
	MyApp::Animal
	MyApp::Mammal
	MyApp::Primate
	Human
	MyApp::Superhuman
);

my $worker = MyApp->new_human_employee(name => 'Bob', job_title => 'Uncle');

is($worker->job_title, 'Uncle');

is($worker->bleh, 'MyApp');

isa_ok($worker, $_, "\$worker") for qw(
	MyApp::Animal
	MyApp::Mammal
	MyApp::Primate
	Human
	Human::Employee
);

my $bugs = MyApp->new_rabbit;

isa_ok($bugs, $_, "\$bugs") for qw(
	MyApp::Animal
	MyApp::Mammal
	MyApp::Rabbit
);

my $hawkeye = MyApp->new_eagle;
is( $hawkeye->environment, 'sky' );
ok( $hawkeye->does('MyApp::EagleEyed') );
ok( ! $hawkeye->does('MyApp::Environment') );

done_testing;
