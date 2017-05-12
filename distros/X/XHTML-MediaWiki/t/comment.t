use Test::More;

use Test::XML tests => 1;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($xhtml, $cmp);

$xhtml = $mediawiki->format(<<EOT);
<div>
<!-- This is a comment -->
</div>
EOT

$cmp = <<EOT;
<div>
</div>
EOT

is_xml($xhtml, $cmp, "books and baskets");

