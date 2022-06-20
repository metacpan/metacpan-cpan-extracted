use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Requires 'Sub::MultiMethod';

use Types::Standard -types;

my $foo;

package My {
	use Zydeco;
	
	class Class {
		with RoleA, RoleB;
		multi method $foo (HashRef $hash) {
			return "C";
		}
	}
	
	role RoleA {
		with RoleC;
		multi method $foo :alias(foo_a) (HashRef $hash) = 'A';
	}

	role RoleB {
		multi method $foo (ArrayRef $array) {
			return "B";
		}
	}
	
	role RoleC {
		multi method $foo () = $self;
	}
};

ok !exists &My::RoleA::foo;
ok !exists &My::RoleB::foo;
ok !exists &My::Class::foo;
ok  exists &My::RoleA::foo_a;
ok  exists &My::Class::foo_a;

my $obj = My::Class->new;

is( $obj->foo_a({}), 'A' );
is( $obj->$foo([]), 'B' );

# Undefined behaviour
my $got = $obj->$foo({});
ok( $got eq 'A' or $got eq 'C' );

is_deeply($obj->$foo, $obj);

done_testing;
