use Test2::V0 -no_srand => 1;
use Test2::Require::Internet ();
use IO::Socket::INET;

isa_ok 'Test2::Require::Internet', 'Test2::Require';

delete $ENV{NO_NETWORK_TESTING};

is(
  do {
    local $ENV{NO_NETWORK_TESTING} = 1;
    Test2::Require::Internet->skip()
  },
  'NO_NETWORK_TESTING',
  'environmental override',
);

my $listen = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1',
  Listen    => 1,
  Reuse     => 1,
);
my $port = $listen->sockport;

note "listening to 127.0.0.1:$port";

is(
  Test2::Require::Internet->skip( -tcp => [ '127.0.0.1', $port ] ),
  undef,
  'okay when port is open',
);

note "closing connection to 127.0.0.1:$port";
$listen->close;
undef $listen;

is(
  Test2::Require::Internet->skip( -tcp => [ '127.0.0.1', $port ] ),
  "Unable to connect to 127.0.0.1:$port/tcp",
  'skip when unable to connect',
);

done_testing
