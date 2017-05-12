
use Test::More;

use Test::XML tests => 4;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
Paragraph 1.
EOT
$xhtml = "<div>" . $xhtml . "</div>\n";

$cmp = <<EOT;
<div>
<p>Paragraph 1.</p>
</div>
EOT

is_xml($xhtml, $cmp, "2 auto paragraphs");

$xhtml = $mediawiki->format(<<EOT);
Paragraph 1.
Paragraph 1.
Paragraph 1.

Paragraph 2.
Paragraph 2.
Paragraph 2.
EOT
$xhtml = "<div>" . $xhtml . "</div>\n";

$cmp = <<EOT;
<div>
<p>Paragraph 1.
Paragraph 1.
Paragraph 1.
</p>
<p>
Paragraph 2.
Paragraph 2.
Paragraph 2.
</p>
</div>
EOT
is_xml($xhtml, $cmp, "2 paragraphs");

# test a <p> emeded between to auto paragraphs

$xhtml = $mediawiki->format(<<EOT);
Paragraph 1.
Paragraph 1.
Paragraph 1.
<p>This is a test paragraph.</p>
Paragraph 2.
Paragraph 2.
Paragraph 2.
EOT

$xhtml = "<div>" . $xhtml . "</div>\n";

$cmp = <<EOT;
<div>
<p>Paragraph 1.
Paragraph 1.
Paragraph 1.
</p>
<p>This is a test paragraph.</p>
<p>
Paragraph 2.
Paragraph 2.
Paragraph 2.
</p>
</div>
EOT

is_xml($xhtml, $cmp, "paragraph in auto_paragraph");

$xhtml = $mediawiki->format(<<EOT);
<div>
<p>This

is

a

test

paragraph.</p>
</div>
EOT

$cmp = <<EOT;
<div>
<p>This is a test paragraph.</p>
</div>
EOT

is_xml($xhtml, $cmp, "empty line in a paragraph");


