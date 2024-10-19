use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

my $basename = "Acme-CPANAuthors-Japanese-0.071226.tar.gz";
for my $prefix (qw{I/IS/ISHIGAKI ISHIGAKI}) {
  my $path = "$prefix/$basename";

  my $worepan = WorePAN->new(files => [$path], no_network => 0, cleanup => 1, use_backpan => 1);

  my $dest = $worepan->file($path);

  ok $dest->exists, "downloaded successfully";

  my $ver = $worepan->look_for('Acme::CPANAuthors::Japanese');
  is $ver => '0.071226', "correct version";
}

done_testing;
