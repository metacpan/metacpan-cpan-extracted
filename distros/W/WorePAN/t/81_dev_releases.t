use strict;
use warnings;
use Test::More;
use WorePAN;

plan skip_all => "set WOREPAN_NETWORK_TEST to test" unless $ENV{WOREPAN_NETWORK_TEST};

for my $allow_dev (0..1) {
  my $worepan = WorePAN->new(
    files => [qw{
      ISHIGAKI/DBD-SQLite-1.43_07.tar.gz
      ISHIGAKI/DBD-SQLite-1.42.tar.gz
    }],
    cleanup => 1,
    use_backpan => 1,
    no_network => 0,
    developer_releases => $allow_dev,
  );
  my @lines = $worepan->slurp_packages_details;

  if ($allow_dev) {
    ok grep /1\.43_07/, @lines;
  } else {
    ok !grep /1\.43_07/, @lines;
  }
  note join "\n", @lines, "";
}

done_testing;
