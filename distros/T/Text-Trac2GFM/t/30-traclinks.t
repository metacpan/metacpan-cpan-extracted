use strict;
use warnings;

use Test::More tests => 4;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
See issue #4.
EOG
$expect = <<EOE;
See issue #4.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'simple ticket link');

$give = <<EOG;
Prefix ticket:5. Another bug:3.
EOG
$expect = <<EOE;
Prefix #5. Another #3.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'prefix style ticket link');

$give = <<EOG;
Changeset r1234 link.
Another changeset:5678 link.
Yet another [97531] changeset.
EOG
$expect = <<EOE;
Changeset 1234 link.
Another 5678 link.
Yet another 97531 changeset.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'changesets with no mapping');

$give = <<EOG;
Changeset r1234 link.
Another changeset:5678 link.
Yet another [97531] changeset.
EOG
$expect = <<EOE;
Changeset deadbeaf link.
Another abcd1234 link.
Yet another a1b2c3d4 changeset.
EOE
cmp_ok(trac2gfm($give, { commits => { 1234 => 'deadbeaf', 5678 => 'abcd1234', 97531 => 'a1b2c3d4' }}), 'eq', $expect, 'changesets with mappings');

