use Test::More tests => 1;
use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
a [[micro]]second

a [[micro]]<nowiki>second</nowiki>

a [[micro]]<nowiki>second</nowiki> and extra.
EOT

$xhtml = "<div>" . $xhtml . "</div>";

$cmp = <<EOP;
<div>
<p>a <a href="micro">microsecond</a></p>
<p>a <a href="micro">micro</a>second</p>
<p>a <a href="micro">micro</a>second and extra.</p>
</div>
EOP

is_xml($xhtml, $cmp, 'blending');

