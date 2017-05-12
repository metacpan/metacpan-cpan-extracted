use Test::More tests => 3;

use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
<pre>
This is pre nowiki text [[asdf]]
</pre>
 This is pre text [[asdf]]
</div>
EOT

$cmp = <<EOP;
<div>
<pre>
This is pre nowiki text [[asdf]]
</pre>
<pre>
This is pre text <a href="asdf">asdf</a>
</pre>
</div>
EOP

is_xml($xhtml, $cmp, 'pre');

$xhtml = $mediawiki->format(<<EOT);
<div>
 This is one

 This is two
</div>
EOT

$cmp = <<EOP;
<div>
<pre>
This is one
</pre>
<pre>
This is two
</pre>
</div>
EOP

is_xml($xhtml, $cmp, 'pre seperate');

$xhtml = $mediawiki->format(<<EOT);
<div>
 This is line one
 This is line two
</div>
EOT

$cmp = <<EOP;
<div>
<pre>
This is line one
This is line two
</pre>
</div>
EOP

is_xml($xhtml, $cmp, 'pre multi-line');

