use strict;
use warnings;

use vars qw($loaded);

use Test::More tests => 2;

use XML::LibXSLT ();

# TEST
ok( 1, ' use loading worked' );

my $p = XML::LibXSLT->new();

# TEST
ok( $p, ' object was initialized.' );
