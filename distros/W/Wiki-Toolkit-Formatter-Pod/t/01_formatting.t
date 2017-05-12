use Test::More tests => 5;

use_ok( "Wiki::Toolkit::Formatter::Pod" );

my $formatter = Wiki::Toolkit::Formatter::Pod->new;
isa_ok( $formatter, "Wiki::Toolkit::Formatter::Pod" );

my $pod = "A L<TestLink>";
my $html = $formatter->format($pod);
like( $html, qr/<A HREF="wiki.cgi\?node=TestLink">/,
      "links to other wiki page" );

$formatter = Wiki::Toolkit::Formatter::Pod->new(
                                        node_prefix => "wiki-pod.cgi?node=" );
isa_ok( $formatter, "Wiki::Toolkit::Formatter::Pod" );
$html = $formatter->format($pod);
like( $html, qr/<A HREF="wiki-pod.cgi\?node=TestLink">/,
      "...still works when we redefine node prefix" );
