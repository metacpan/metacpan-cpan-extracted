use strict;
use warnings;

use Test::More tests => 1;

use YottaDB qw/:all/;

ok (y_get ('$ZYRELEASE') =~ /^YottaDB/);

