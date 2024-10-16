use Test::More tests=>5;
use Test::WWW::Simple;
use Test::Warnings qw(:all);

ok(user_agent(), "null agent");
like((warning { ok(user_agent("Farnesworth")) }), qr/Unknown agent alias "Farnesworth"/, "correct warning about agent");
ok(user_agent("Mac Safari"), "acceptable agent");
