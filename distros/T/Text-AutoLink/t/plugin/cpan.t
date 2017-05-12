use strict;
use Test::More tests => 4;

BEGIN { use_ok("Text::AutoLink") }

my $auto = Text::AutoLink->new(plugins => ['Text::AutoLink::Plugin::CPAN']);
my $text = $auto->parse_string(<<EOS);
    cpan://Text-AutoLink
    cpan://HTML::TreeBuilder
    cpan://CPAN
EOS

like($text, qr{<a href="http://search.cpan.org/search\?query=Text-AutoLink">});
like($text, qr{<a href="http://search.cpan.org/search\?query=HTML%3A%3ATreeBuilder">});
like($text, qr{<a href="http://search.cpan.org/search\?query=CPAN">});