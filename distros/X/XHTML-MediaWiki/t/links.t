use Test::More tests => 1;

use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
[Test]
</div>
EOT

$cmp = <<EOP;
<div>
<p>[Test]</p>
</div>
EOP

is_xml($xhtml, $cmp, 'pre');

