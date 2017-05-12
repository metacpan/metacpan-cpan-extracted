#
# $Id: 00-load.t,v 1.1.1.1 2002/10/16 10:08:08 ctriv Exp $
#

use Test::More tests => 2;
use strict;

BEGIN { 
    use_ok('Tie::LogFile'); 
}


eval { Tie::LogFile::misc::time2str('%X'); };

ok(!$@, 'Loaded time module.');