use Test::More tests => 1;

use Test::XML;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
 This is prewiki text [[asdf]]
   This text should have indents
     And should not have breaks for long lines.  And should not have breaks for long lines.  And should not have breaks for long lines.  And should not have breaks for long lines.
</div>
EOT

$cmp = <<EOP;
<div>
<pre>This is prewiki text <a href='asdf'>asdf</a>
  This text should have indents
    And should not have breaks for long lines.  And should not have breaks for long lines.  And should not have breaks for long lines.  And should not have breaks for long lines.
</pre></div>
EOP

chomp $cmp;

is($xhtml, $cmp, 'pre');
