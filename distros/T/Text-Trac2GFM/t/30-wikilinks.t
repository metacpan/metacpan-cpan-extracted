use strict;
use warnings;

use Test::More tests => 4;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
This sentence contains a CamelCase link to another page.
EOG
$expect = <<EOE;
This sentence contains a [CamelCase](camel-case) link to another page.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'camel-case wiki link');

$give = <<EOG;
This contains a blocked !CamelCase word that should not be a link.
EOG
$expect = <<EOE;
This contains a blocked CamelCase word that should not be a link.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'non-linked camel-case word');

$give = <<EOG;
Read [wiki:AnotherPage] also.
EOG
$expect = <<EOE;
Read [another-page](another-page) also.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'explicit page link without title');

$give = <<EOG;
Read [wiki:AnotherPage this other thing] also.
EOG
$expect = <<EOE;
Read [this other thing](another-page) also.
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'explicit page link with title');

