use Test::More tests => 3;
use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
This is a test <nowiki>one
line
at

a
[[time]]
</nowiki>
and a [[link]].
EOT

$cmp = <<EOP;
<p>This is a test  one
line
at

a
[[time]]

and a <a href='link'>link</a>.
</p>
EOP

is_xml($xhtml, $cmp, 'nowiki 1');

$xhtml = $mediawiki->format(<<EOT);
<nowiki> No wiki paragragh [[bob]] </nowiki> and a [[link]].
EOT

$cmp = <<EOP;
<p> No wiki paragragh [[bob]] and a <a href="link">link</a>.</p>
EOP

is_xml($xhtml, $cmp, 'nowiki paragraph start');

$xhtml = $mediawiki->format(<<EOT);
<div>
# one <nowiki>[[test]]</nowiki> [[test]]
<nowiki>[[test]] paragraph</nowiki>

[[test]] paragraph
</div>
EOT

$cmp = <<EOP;
<div><ol>
<li>one [[test]] <a href='test'>test</a></li>
</ol>
<p>[[test]] paragraph</p>
<p><a href='test'>test</a> paragraph
</p>
</div>
EOP

is_xml($xhtml, $cmp, 'ordered list and nowiki');

print $xhtml, "\n";
