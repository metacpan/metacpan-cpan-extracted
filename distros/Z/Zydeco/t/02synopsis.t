use v5.14;
use strict;
use warnings;
use Test::More tests => 2;

package MyApp {
	use Zydeco (
		version    => 0.1,
		authority  => 'cpan:MYPAUSEID',
	);
	
	class Person {
		has name   ( type => Str, required => true );
		has gender ( type => Str );
		
		factory new_man (Str $name) {
			return $class->new(name => $name, gender => 'male');
		}
		
		factory new_woman (Str $name) {
			return $class->new(name => $name, gender => 'female');
		}
		
		coerce from Str via from_string {
			return $class->new(name => $_);
		}
		
		method greet (Person *friend, Str *greeting = "Hello") {
			sprintf("%s, %s!", $arg->greeting, $arg->friend->name);
		}
	}
}

use MyApp::Types qw( is_Person );

my $alice  = MyApp->new_woman("Alice");

ok is_Person($alice);

is(
	$alice->greet(friend => "Bob", greeting => 'Hi'),
	'Hi, Bob!',
);
