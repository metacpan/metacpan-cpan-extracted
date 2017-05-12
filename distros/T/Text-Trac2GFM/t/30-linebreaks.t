use strict;
use warnings;

use Test::More tests => 2;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = "foo\r\nbar";
$expect = "foo\nbar";
cmp_ok(trac2gfm($give), 'eq', $expect, 'linebreak translation');

$give = <<EOG;
This is line 1[[BR]]
This is line 2
[[BR]]
This is line 3
EOG
$expect = <<EOE;
This is line 1  
This is line 2  
This is line 3
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'manual linebreak collapse');
