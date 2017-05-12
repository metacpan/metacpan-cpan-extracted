use strict;
use warnings;

use Test::More tests => 1;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
This is just a line of text.

Followed by another line in a separate paragraph.



And a third paragraph that had far too much spacing.
EOG
$expect = <<EOE;
This is just a line of text.

Followed by another line in a separate paragraph.

And a third paragraph that had far too much spacing.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'paragraph spacing');

