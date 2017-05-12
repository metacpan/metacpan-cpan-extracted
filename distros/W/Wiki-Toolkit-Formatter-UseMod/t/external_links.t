use strict;
use Wiki::Toolkit::Formatter::UseMod;
use Test::More tests => 2;

my $wikitext = <<WIKITEXT;

http://external.example.com/

[http://external2.example.com/ foo]

WIKITEXT

my $formatter = Wiki::Toolkit::Formatter::UseMod->new(
                                          external_link_class => "external" );

my $html = $formatter->format( $wikitext );

like( $html,
      qr'<a href="http://external.example.com/" class="external">http://external.example.com/</a>',
      "external links with no title appear as expected" );

like( $html,
      qr'<a href="http://external2.example.com/" class="external">foo</a>',
      "external links with title appear as expected" );
