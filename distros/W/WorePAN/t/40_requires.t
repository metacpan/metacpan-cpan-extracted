use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $worepan = WorePAN->new(
  dists => {
    'Acme-CPANAuthors' => 0,
    'Acme-CPANAuthors-Japanese' => 0.071226,
  },
  no_network => 0,
  cleanup => 1,
);

{
  my $ver = $worepan->look_for('Acme::CPANAuthors');
  ok $ver gt "0.11", "Acme::CPANAuthors: $ver";
}

{
  my $ver = $worepan->look_for('Acme::CPANAuthors::Japanese');
  is $ver => '0.071226', "Acme::CPANAuthors::Japanese: $ver";
}

done_testing;
