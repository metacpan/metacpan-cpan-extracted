
use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;
#use Test::UniqueTestNames ;

BEGIN { use_ok( 'Text::Colorizer' ) or BAIL_OUT("Can't load module"); } ;

my $object = new Text::Colorizer ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, 'Text::Colorizer');

my $new_config = $object->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'Text::Colorizer');

dies_ok
	{
	Text::Colorizer::new () ;
	} "invalid constructor" ;
