use Test::More;
use Tie::Redis;
use t::Redis;

test_redis {
  my($port) = @_;
  plan tests => 3 + 10;

  # Use two connections, to ensure we aren't caching locally (very unlikely, we
  # don't cache yet).
  tie my %r_w, "Tie::Redis", port => $port;
  tie my %r_r, "Tie::Redis", port => $port;

  # List
  $r_w{list} = [1];
  is scalar @{$r_r{list}}, 1;

  $r_w{list} = [1 .. 10];
  is_deeply $r_r{list}, [ 1 .. 10];

  is shift @{$r_r{list}}, $_ for 1 .. 10;
  is $r_r{list}, undef; # Empty lists become none in Redis

};
