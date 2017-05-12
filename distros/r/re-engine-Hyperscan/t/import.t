use strict;
use Test::More tests => 4;
use re::engine::Hyperscan ();

re::engine::Hyperscan->import;
ok(exists $^H{regcomp}, '$^H{regcomp} exists');
cmp_ok($^H{regcomp}, '!=', 0);

{
  no re::engine::Hyperscan;
  my $qr = qr/b/;
  isnt(ref $qr, "re::engine::Hyperscan", 'not Hyperscan, but');
  is(ref $qr, "Regexp", 'core re class');
}
