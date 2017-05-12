use Test::More tests => 2;
use re::engine::Lua;

my $re = qr/aoeu/;

isa_ok($re, "re::engine::Lua");
is("$re", "/aoeu/");
