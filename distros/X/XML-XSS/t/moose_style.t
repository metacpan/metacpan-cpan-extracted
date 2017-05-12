use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 1;                      # last test to print

use C;

my $xml = '<doc><foo/></doc>';

is( C->new->render( $xml ), '<doc>FOO</doc>' );



