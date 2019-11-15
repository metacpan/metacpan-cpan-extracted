use strict;
use warnings;
use Test::More;

use constant BEFORE => 10;

use unconstant;

use constant AFTER => 10;

my $before = BEFORE + 10;
is( $before, 20, 'constants parsed as expected' );

my $after = AFTER + 10;
is( $after, 20, 'unconstants parsed as expected' );


done_testing;
