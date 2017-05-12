use Test::More tests => 3;

BEGIN { use_ok('Tie::Hash::Create') };

my $hr = Tie::Hash::Create->newHASH;
%$hr = qw(no matter what one choose hm);
ok (tied(%$hr)->[1] == $hr, 'tie-object stored reference of tied array');
ok (1, 'bye, more tests of this automatically come with derived class Tie::Hash::KeysMask');