
use Test::More tests => 2;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my ($got, $expected);

$got = $mediawiki->format_line(<<EOT);
= 'H1' =
= ''H1'' =
= '''H1''' =
EOT

$expected = <<EOT;
= 'H1' =
= <em>H1</em> =
= <strong>H1</strong> =
EOT

is($got, $expected, "Emphasize");

$got = $mediawiki->format_line(<<EOT);
[[bob]]
[[bob|Bill]]
[html://bob.com/ bob smith]
html://bob.com/ bob smith
EOT

$expected = <<EOT;
<a href='bob'>bob</a>
<a href='bob|Bill'>bob|Bill</a>
<a href='html://bob.com/ bob smith'>1</a>
html://bob.com/ bob smith
EOT

is($got, $expected, "Links");

