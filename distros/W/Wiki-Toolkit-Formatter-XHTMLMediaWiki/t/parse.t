
use Test::More tests => 1;

use Wiki::Toolkit::Formatter::XHTMLMediaWiki;

my $wiki = Wiki::Toolkit::Formatter::XHTMLMediaWiki->new();

my $out = $wiki->format(<<EOT);
This is a test of [[wikilinks]]
EOT

is($out, qq(<p>This is a test of <a href='wikilinks'>wikilinks</a></p>\n), 'compare');


