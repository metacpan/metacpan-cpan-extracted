use strict;
use warnings;

use Test::More tests => 1;

use Text::Trac2GFM qw( trac2gfm );

cmp_ok(trac2gfm('foo'), 'eq', 'foo');

