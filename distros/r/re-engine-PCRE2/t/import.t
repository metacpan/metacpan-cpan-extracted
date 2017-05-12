use strict;
use Test::More tests => 4;
use re::engine::PCRE2 ();

re::engine::PCRE2->import;
ok(exists $^H{regcomp}, '$^H{regcomp} exists');
cmp_ok($^H{regcomp}, '!=', 0);

{
  no re::engine::PCRE2;
  my $qr = qr/b/;
  isnt(ref $qr, "re::engine::PCRE2", 'not PCRE2, but');
  is(ref $qr, "Regexp", 'core re class');
}
