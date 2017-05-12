use strict;
use warnings;

use Test::More tests => 2;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
== Heading ==
EOG
$expect = <<EOE;
## Heading
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'well-formed heading');

$give = <<EOG;
= Heading 1 =
== Heading 2 ==
===Heading 3===
====Heading 4
===== Heading 5 =====
EOG
$expect = <<EOE;
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'multiple headings, including malformed');

