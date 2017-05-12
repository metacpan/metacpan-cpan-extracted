use Test::More tests=>3;
use Test::WWW::Simple;

ok(user_agent(), "null agent");
ok(user_agent("Farnesworth"), "bogus agent");
ok(user_agent("Mac Safari"), "acceptable agent");
