use strict;
use Wiki::Toolkit::Formatter::Markdown;
use Test::More tests => 2;

my $wikitext = <<WIKITEXT;

http://external.example.com/

[foo](http://external2.example.com)

WIKITEXT

my $formatter = Wiki::Toolkit::Formatter::Markdown->new;

my $html = $formatter->format( $wikitext );

like( $html,
      qr'<p>http://external.example.com/</p>',
      "external links with no title appear as expected" );

like( $html,
      qr'[<a href="http://external2.example.com/">foo</a>]',
      "external links with title appear as expected" );
