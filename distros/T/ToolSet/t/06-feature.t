use strict;
use lib '.';
use Test::More;

if ( $] < 5.010 ) {
    plan skip_all => "feature.pm requires perl 5.10";
}
else {
    plan tests => 1;
}

#--------------------------------------------------------------------------#
# Test feature propogation
#--------------------------------------------------------------------------#

# Catch warning
require_ok("t::Sample::HasFeature");

