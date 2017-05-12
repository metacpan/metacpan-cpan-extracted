use strict;
use warnings;

use Test::More tests => 4;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
A sentence with '''bolded''' words '''and phrases with snake_casing.'''
EOG
$expect = <<EOE;
A sentence with **bolded** words **and phrases with snake_casing.**
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'bolded emphasis');

$give = <<EOG;
A sentence with ''italicized'' words ''and phrases with snake_casing.''
EOG
$expect = <<EOE;
A sentence with _italicized_ words _and phrases with snake_casing._
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'italicized emphasis');

$give = <<EOG;
A sentence with __underlined__ words __and phrases with snake_casing.__
EOG
$expect = <<EOE;
A sentence with <ul>underlined</ul> words <ul>and phrases with snake_casing.</ul>
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'underlined emphasis');

$give = <<EOG;
Some '''nested __emphasis the ''likes of which''__''' you '''''shouldn't''''' ever see.
EOG
$expect = <<EOE;
Some **nested <ul>emphasis the _likes of which_</ul>** you **_shouldn't_** ever see.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'nested emphasis');

