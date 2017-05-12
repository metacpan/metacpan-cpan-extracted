# Test::MockRandom
use strict;

use Test::More tests => 3;

#--------------------------------------------------------------------------#
# Test package overriding via import
#
# In case __PACKAGE__ winds up in a qw() list, the import will still work
#--------------------------------------------------------------------------#

use Test::MockRandom qw( __PACKAGE__ ); # "__PACKAGE__"

for (qw ( rand srand oneish )) {
    can_ok( __PACKAGE__, $_ );
}
