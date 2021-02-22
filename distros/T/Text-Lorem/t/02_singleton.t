use strict;
use warnings;

use Test::More;

my $class = 'Text::Lorem';
use_ok($class);

my $object = $class->new();
my $object_singleton = $class->new();

ok( $object_singleton == $object, 'new instance is a singleton of the original' );

done_testing();
