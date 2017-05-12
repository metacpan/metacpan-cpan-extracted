use Test::More tests => 1;

use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
a
<ruby>
a
<![CDATA[ This is CDATA ]]>
b
</ruby>
</div>
EOT

$cmp = <<EOP;
<div>
<p>a</p>
Ruby Data
</div>
EOP

is_xml($xhtml, $cmp, 'cdata');

