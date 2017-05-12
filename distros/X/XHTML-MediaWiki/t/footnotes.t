use strict;
use warnings;
use Test::More tests => 4;

use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($text, $cmp, $data);

$text = <<EOT;
<div>
Note [http://example.com/]

Note [http://example.com/]
</div>
EOT

$cmp = $mediawiki->format($text);

is_well_formed_xml($cmp, 'well formed');

$mediawiki->reset_counters;

$data = $mediawiki->format($text);

is($cmp, $data, 'reset');

$data = $mediawiki->format($text);

isnt($cmp, $data, 'no reset');

$mediawiki->reset_counters;

$data = $mediawiki->format($text);

is($cmp, $data, 'check again');

