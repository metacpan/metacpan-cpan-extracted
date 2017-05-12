use Test::More;

use Test::XML tests => 1;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
= H1 =
== H2 ==
<nowiki>
= H1 =
== H2 ==
</nowiki>
= H1 =
== H2 ==
</div>
EOT

$cmp = <<EOT;
<div>
<a name='H1'></a><h1>H1</h1>
<a name='H2'></a><h2>H2</h2>
<p>
= H1 =
== H2 ==
</p>
<a name='H1'></a><h1>H1</h1>
<a name='H2'></a><h2>H2</h2>
</div>
EOT

is_xml($xhtml, $cmp, "nowiki");


