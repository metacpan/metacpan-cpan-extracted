use strict;
use warnings;

use Test::More tests => 4;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
Linking to http://google.com/ without markup.
EOG
$expect = <<EOE;
Linking to http://google.com/ without markup.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'no-markup external link');

$give = <<EOG;
Linking to [http://google.com/ Google] by name.
EOG
$expect = <<EOE;
Linking to [Google](http://google.com/) by name.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'named external link');

$give = <<EOG;
Linking to [http://google.com/] with markup but no name.
EOG
$expect = <<EOE;
Linking to http://google.com/ with markup but no name.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'unnamed external link');

$give = <<EOG;
Linking to [http://google.com/ ] with markup, no name, but an errant space.
EOG
$expect = <<EOE;
Linking to http://google.com/ with markup, no name, but an errant space.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'extra whitespace on unnamed external link');

