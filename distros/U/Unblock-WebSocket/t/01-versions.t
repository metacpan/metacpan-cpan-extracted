use strict;
use warnings;
use Test::More;

use Unblock::WebSocket;
use Unblock::WebSocket::Client;
use Unblock::WebSocket::Server;
use Unblock::WebSocket::Handshake;

my $version = $Unblock::WebSocket::VERSION;
ok defined($version) && length($version), 'distribution has a version';

is $Unblock::WebSocket::Client::VERSION, $version,
    'client package version matches distribution';
is $Unblock::WebSocket::Server::VERSION, $version,
    'server package version matches distribution';
is $Unblock::WebSocket::Handshake::VERSION, $version,
    'handshake package version matches distribution';

done_testing;
