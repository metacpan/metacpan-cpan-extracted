use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok( 'Time::Stats' ); }
can_ok('Time::Stats', 'clear', 'mark', 'stats');
