
use Test::More;

use Test::XML tests => 1;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
Paragraph 1.


Paragraph 2.
</div>
EOT

$cmp = <<EOT;
<div>
<p>Paragraph 1.</p>
<p><br />
Paragraph 2.</p>
</div>
EOT

is_xml($xhtml, $cmp, "paragraph break before");

