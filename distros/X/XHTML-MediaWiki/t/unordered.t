use Test::More tests => 1;
use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
* one
** one.one
* two
* three
EOT
$xhtml = "<div>" . $xhtml . "</div>";

$cmp = <<EOP;
<div>
<ul>
 <li>one<ul>
  <li>one.one</li></ul>
 </li>
 <li>two</li>
 <li>three</li>
 </ul>
</div>
EOP

is_xml($xhtml, $cmp, 'simple unordered list');

