use Test::More tests => 4;
use Test::WWW::Simple;

# Test::WWW::Simple should have imported page_like and page_unlike

ok(defined \&page_like, "page_like imported");
ok(defined \&page_unlike, "page_unlike imported");
ok(defined \&cache, "cache imported");
ok(defined \&no_cache, "no_cache imported");

