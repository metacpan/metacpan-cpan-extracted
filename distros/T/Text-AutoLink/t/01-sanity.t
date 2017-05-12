#!perl
use strict;
use Test::More tests => 6;

BEGIN { use_ok("Text::AutoLink") }

my $auto = Text::AutoLink->new();
ok($auto);
ok($auto->plugins);
my $ret =$auto->parse_string(<<EOS);
    http://search.cpan.org/ ftp://ftp.cpan.org mailto:dmaki\@cpan.org
EOS
like($ret, qr{<a href="http://search.cpan.org/">});
like($ret, qr{<a href="ftp://ftp.cpan.org">});
like($ret, qr{<a href="mailto:dmaki\@cpan.org">});