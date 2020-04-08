use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	
	class Widget {
		has foo (predicate => true);
		has bar (predicate => true);
		
		multi factory new_widget ( ArrayRef $bar ) {
			$class->new( bar => $bar );
		}
		
		multi factory new_widget ( Int $foo ) {
			$class->new( foo => $foo );
		}
	}
}

ok( MyApp->new_widget(42)->has_foo );
ok( MyApp->new_widget([])->has_bar );

done_testing;
