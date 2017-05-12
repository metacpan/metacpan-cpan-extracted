use strict;
use warnings;

use Test::Stream -V1, 'Explain::Terse';

# ABSTRACT: Make sure the magic Test::Stream API works with us.

ok( $INC{'Test/Stream/Plugin/Explain/Terse.pm'}, "Load plugin ok" ) or do {
  diag( "[" . wrap( " ", " ", join qq[, ], sort keys %INC ) . "]" );
};

can_ok( __PACKAGE__, 'explain_terse' );

done_testing;
