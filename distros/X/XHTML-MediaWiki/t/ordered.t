use Test::More tests => 1;
use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
# one
## one.one
### one.one.three
## one.two
# two
## two.one
# three
</div>
EOT

$cmp = <<EOP;
<div><ol>
<li>one<ol>
<li>one.one<ol>
<li>one.one.three</li>
</ol>
</li>
<li>one.two</li>
</ol>
</li>
<li>two<ol>
<li>two.one</li>
</ol>
</li>
<li>three</li>
</ol>
</div>
EOP

is_xml($xhtml, $cmp, 'simple ordered list');

