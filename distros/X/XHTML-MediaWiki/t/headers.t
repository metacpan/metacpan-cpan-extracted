use Test::More tests => 3;
use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

if (1) {
$xhtml = $mediawiki->format(<<EOT);
<div>
= H1 =
</div>
EOT

$cmp = <<EOP;
<div><a name="H1"></a><h1>H1</h1></div>
EOP

is_xml($xhtml, $cmp, 'header');
}

$xhtml = $mediawiki->format(<<EOT);
<div>
= H1 =
= H2==
</div>
EOT

$cmp = <<EOP;
<div>
 <a name="H1"></a><h1>H1</h1>
 <a name="H2="></a><h1>H2=</h1>
</div>
EOP

is_xml($xhtml, $cmp, 'header');

if (1) {
$xhtml = $mediawiki->format(<<EOT);
<div>
= H1 =
== H2 ==
=== H3 ===
==== H4 ====
===== H5 =====
====== H6 ======
======= H7 =======
</div>
EOT

$cmp = <<EOP;
<div>
 <a name="H1"></a><h1>H1</h1>
 <a name="H2"></a><h2>H2</h2>
 <a name="H3"></a><h3>H3</h3>
 <a name="H4"></a><h4>H4</h4>
 <a name="H5"></a><h5>H5</h5>
 <a name="H6"></a><h6>H6</h6>
 <a name="=_H7_="></a><h6>= H7 =</h6>
</div>
EOP

is_xml($xhtml, $cmp, 'header');
}
