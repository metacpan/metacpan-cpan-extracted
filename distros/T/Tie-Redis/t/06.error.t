use Test::More tests => 1;
use Tie::Redis;
eval {
  tie my %r, "Tie::Redis", port => 3; # hopefully nothing running here..
  my $x = $r{a};
};
like $@, qr/Unable to connect to Redis server:/;

