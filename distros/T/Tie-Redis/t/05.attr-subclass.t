use t::Redis;
use Test::More;

BEGIN {
  plan skip_all => "Needs Perl >= 5.10.1" unless $^V >= v5.10.1;
}

our $port;

BEGIN {
  package My::RedisSubclass;
  use parent "Tie::Redis::Attribute";

  sub server {
    my($class, %args) = @_;
    return Tie::Redis::Connection->new(port => $port);
  }
}

BEGIN {
  My::RedisSubclass->import;
}

test_redis {
  ($port) = @_;
  plan tests => 1;

  tie my %r, "Tie::Redis", port => $port;
  my %special : Redis;

  for(1 .. 100) {
    $special{$_} = rand;
  }

  is_deeply \%special, $r{(keys %r)[0]};
};
