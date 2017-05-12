use Test::More tests => 2;
use re::engine::LPEG;

my $re = qr/"aoeu"/;

isa_ok($re, "re::engine::LPEG");
is("$re", '"aoeu"');
