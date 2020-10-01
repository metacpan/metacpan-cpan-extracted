use strict;
use warnings;
use Data::Dumper;

package MyApp {
	use Zydeco;
	
	class Foobar {
		toolkit Moose;
		has foo;
		has bar;
	}
}

$Data::Dumper::Deparse  = 1;

print Dumper( 'MyApp::Foobar'->meta );
