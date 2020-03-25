use strict;
use warnings;
use Test::More;

package MyApp {
	use Zydeco;
	
	class Box {
		has width, height, depth (required => true, type => Num);
		
		factory new_box via _new;

		multi method _new ( Num *width, Num *height, Num *depth ) = $class->new( %$arg );
		
		multi method _new ( Num *length ) {
			return $class->new(
				width  => $arg->length,
				height => $arg->length,
				depth  => $arg->length,
			);
		}
		
		multi method _new ( Num $n ) = $class->_new(length => $n);
	}
}

is_deeply(
	MyApp->new_box( length => 42 ),
	bless({ width => 42, height => 42, depth => 42 } => 'MyApp::Box'),
);

is_deeply(
	MyApp->new_box( width => 1, height => 2, depth => 3 ),
	bless({ width => 1, height => 2, depth => 3 } => 'MyApp::Box'),
);

is_deeply(
	MyApp->new_box( { width => 1, height => 2, depth => 3 } ),
	bless({ width => 1, height => 2, depth => 3 } => 'MyApp::Box'),
);

is_deeply(
	MyApp->new_box( 666 ),
	bless({ width => 666, height => 666, depth => 666 } => 'MyApp::Box'),
);

done_testing;
