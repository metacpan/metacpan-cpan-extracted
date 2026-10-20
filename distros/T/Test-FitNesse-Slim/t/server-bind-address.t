#! perl

use strict;
use warnings;

use IO::Socket::INET;
use Socket qw(unpack_sockaddr_in inet_ntoa);
use Test::More;
use Test::FitNesse::Slim::Server;

sub local_address {
  my ($socket) = @_;
  my (undef, $address) = unpack_sockaddr_in($socket->sockname);
  return inet_ntoa($address);
}

# Before the LocalAddr correction, IO::Socket::INET's equivalent default
# construction reported 0.0.0.0 from getsockname. Keep the address assertion
# here so the listener cannot regress to wildcard binding.
my $default = Test::FitNesse::Slim::Server->new;
my $socket = $default->_listen_socket(0);
is(local_address($socket), '127.0.0.1',
  'default TCP listener binds to the actual IPv4 loopback address');
close $socket;

my $occupied = IO::Socket::INET->new(
  LocalAddr => '127.0.0.1', LocalPort => 0,
  Proto => 'tcp', Listen => 1, ReuseAddr => 1,
) or die "reserve loopback port: $!";
my $occupied_port = $occupied->sockport;
my $bound = eval { Test::FitNesse::Slim::Server->new->_listen_socket($occupied_port); 1 };
ok(!$bound, 'loopback bind failure is returned instead of falling back');
like($@, qr/create listen socket on 127\.0\.0\.1:$occupied_port failed/,
  'bind failure identifies the selected address and port');
close $occupied;

$socket = Test::FitNesse::Slim::Server->new(bind_address => '127.0.0.1')->_listen_socket(0);
is(local_address($socket), '127.0.0.1',
  'explicit loopback binding uses the requested address');
close $socket;

my $warning = '';
{
  local $SIG{__WARN__} = sub { $warning .= join '', @_ };
  $socket = Test::FitNesse::Slim::Server->new(bind_address => '0.0.0.0')->_listen_socket(0);
}
is(local_address($socket), '0.0.0.0',
  'explicit all-interface binding uses the requested address');
like($warning, qr/0\.0\.0\.0.*unauthenticated.*trusted network/,
  'non-loopback programmatic binding warns about unauthenticated access');
close $socket;

for my $invalid ('999.1.1.1', '127.0.0', '127.1', 'localhost', '::1', undef) {
  my $ok = eval { Test::FitNesse::Slim::Server->new(bind_address => $invalid); 1 };
  ok(!$ok, 'invalid or non-IPv4 bind address is rejected');
  like($@, qr/invalid IPv4 bind address/, 'invalid bind address is identified clearly');
}

my $pipe_server = Test::FitNesse::Slim::Server->new(bind_address => '127.0.0.1');
my $pipe_ok = eval { $pipe_server->run(1); 1 };
ok(!$pipe_ok, 'explicit bind-address configuration is rejected with pipe mode');
like($@, qr/bind_address cannot be used with pipe mode/,
  'pipe-mode conflict has a specific diagnostic');

done_testing;
