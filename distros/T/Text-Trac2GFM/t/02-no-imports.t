use strict;
use warnings;

use Test::More tests => 2;

use Text::Trac2GFM;

my $title;
eval { $title = gfmtitle('foo'); };
cmp_ok($title // '', 'ne', 'foo', 'gfmtitle improperly imported by default');

my $markup;
eval { $markup = trac2gfm('foo'); };
cmp_ok($markup // '', 'ne', 'foo', 'trac2gfm improperly imported by default');
