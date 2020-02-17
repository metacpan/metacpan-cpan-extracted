use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	
	class MyClass {
		has foo, *bar, {'baz'} = 42;
		
		method m1 {
			return 666;
		}
		
		method m2 {
			return 999;
		}
		
		around m1, m2 {
			1 + $self->$next(@_);
		}
	}
}

my $o = MyApp->new_myclass;

is($o->foo, 42);
is($o->bar, 42);
is($o->baz, 42);
is($o->m1, 667);
is($o->m2, 1000);

done_testing;
