use Test::More tests => 2;
use re::engine::Hyperscan;

my $re = qr/aoeu/;

TODO: {
  local $TODO = 'missing class';
  isa_ok($re, "re::engine::Hyperscan");
  is("$re", "(?:aoeu)");
}
