use Test::More tests => 2;
use re::engine::PCRE;

my $re = qr/aoeu/;

isa_ok($re, "re::engine::PCRE");
is("$re", "(?-ixm:aoeu)");
