use Test::More tests => 3;
use re::engine::Hyperscan;

my @moo = split //, "moo";
is($moo[0], "m");
is($moo[1], "o");
is($moo[2], "o");
