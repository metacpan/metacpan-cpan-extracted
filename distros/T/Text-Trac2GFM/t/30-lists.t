use strict;
use warnings;

use Test::More tests => 4;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
1) First
2. Second
3] Third
EOG
$expect = <<EOE;
1. First
2. Second
3. Third
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'basic numbered list');

$give = <<EOG;
* First
*Second
* Third
EOG
$expect = <<EOE;
* First
* Second
* Third
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'basic bulleted list');

$give = <<EOG;
a) First
b.Second
c] Third
EOG
$expect = <<EOE;
* First
* Second
* Third
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'basic lettered list');

$give = <<EOG;
1. First
  *Nest First
  *Nest Second
2. Second
3. Third
  1. Third Nest First
    a) More nesting
EOG
$expect = <<EOE;
1. First
  * Nest First
  * Nest Second
2. Second
3. Third
  1. Third Nest First
    * More nesting
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'nested lists');

