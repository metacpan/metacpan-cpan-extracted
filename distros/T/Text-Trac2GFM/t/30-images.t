use strict;
use warnings;

use Test::More tests => 3;

use Text::Trac2GFM qw( trac2gfm );

my ($give, $expect);

$give = <<EOG;
[[Image(http://example.com/foo/bar.jpg)]]
EOG
$expect = <<EOE;
![bar.jpg](/bar.jpg)
EOE
cmp_ok(trac2gfm($give), 'eq', $expect, 'simple image, no options');

$give = <<EOG;
[[Image(http://example.com/foo/bar.jpg)]]
EOG
$expect = <<EOE;
![bar.jpg](http://example.com/images/bar.jpg)
EOE
cmp_ok(trac2gfm($give, { image_base => 'http://example.com/images/' }), 'eq', $expect, 'simple image with image_base');

$give = <<EOG;
Inline image [[Image(http://example.com/foo/bar.jpg)]] with some text.
EOG
$expect = <<EOE;
Inline image ![bar.jpg](http://example.com/images/bar.jpg) with some text.
EOE
cmp_ok(trac2gfm($give, { image_base => 'http://example.com/images/' }), 'eq', $expect, 'simple image with image_base');

