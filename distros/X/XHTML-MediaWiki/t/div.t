use Test::More tests => 2;
use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

#### test 1

$xhtml = $mediawiki->format(<<EOT);
<div>
<b>asdf
</div>
EOT

$cmp = <<EOP;
<div>
 <p><b>asdf</b></p>
</div>
EOP

is_xml($xhtml, $cmp, 'div test 1');

#### test 2

$xhtml = $mediawiki->format(<<EOT);
<div>
<div>
first
</div>
<div>
second
</div>
</div>
EOT

$cmp = <<EOP;
<div>
 <div>
  <p>first</p>
 </div>
 <div>
  <p>second</p>
 </div>
</div>
EOP

is_xml($xhtml, $cmp, 'blending');

