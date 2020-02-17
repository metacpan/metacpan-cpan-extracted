use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp {
	use Zydeco;
	class Foo {
		has $bizzle ( type => Int );
		
		method $private :optimize ( Int $x ) {
			return $x + 1;
		}
		
		method do_tests () {
			::ok(!$self->can('bizzle'), 'no normal accessor method created for bizzle');
			::ok(!exists $self->{bizzle}, 'bizzle not set by constructor');
			$self->$bizzle(666);
			::is($self->$bizzle, 666, 'lexical accessor works');
			::is($self->$private(998), 999, 'lexical method works too');
		}
	}
}

note 'simple';

MyApp->new_foo(bizzle => 42)->do_tests();

note 'delegation';

package MyApp2 {
	use Zydeco;
	class Foo {
		has bizzle (
			is           => private,
			isa          => ArrayRef[Int],
			handles_via  => 'Array',
			handles      => [
				push_bizzle => 'push',
				pop_bizzle  => 'pop',
			],
		) = [];
	}
}

my $obj2 = MyApp2->new_foo(bizzle => 42);

ok(!$obj2->can('bizzle'), 'no normal accessor method created for bizzle');
ok(!exists $obj2->{bizzle}, 'bizzle not set by constructor');

$obj2->push_bizzle(666);
$obj2->push_bizzle(999);
$obj2->push_bizzle(420);

is($obj2->pop_bizzle, 420);
is($obj2->pop_bizzle, 999);
is($obj2->pop_bizzle, 666);

done_testing;
