#! perl

use strict;
use utf8;
use warnings;

use Encode qw(encode decode);
use IO::Handle;
use Socket;
use lib 'lib', 't/lib';

use Test::More tests => 4;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::Server;

my ($server_socket, $client_socket);
socketpair $server_socket, $client_socket, AF_UNIX, SOCK_STREAM, PF_UNSPEC
  or die "socketpair failed: $!";
$_->autoflush(1) for $server_socket, $client_socket;

my $payload = "Köln \x{1F600}";
my $command = Test::FitNesse::Slim::List->new([
  ['i', 'import', 'fitnesse.slim.test'],
  ['m', 'make', 'actor', 'TestSlim'],
  ['c', 'call', 'actor', 'echoString', $payload],
])->serialize;
my $command_bytes = encode('UTF-8', $command);
print {$client_socket} sprintf('%06d:', length($command_bytes)), $command_bytes,
  '000003:bye';

Test::FitNesse::Slim::Server->new->process($server_socket);

my $greeting = '';
while ($greeting !~ /\n\z/) {
  my $read = sysread $client_socket, my $part, 1;
  die 'server closed before greeting' unless defined($read) && $read > 0;
  $greeting .= $part;
}
is($greeting, "Slim -- V0.5\n", 'server sends its unframed greeting');
my $header = '';
while (length($header) < 7) {
  my $read = sysread $client_socket, my $part, 7 - length($header);
  die 'server closed before response header' unless defined($read) && $read > 0;
  $header .= $part;
}
like($header, qr/\A[0-9]{6}:\z/, 'response frame uses the six-digit byte-length header');
my ($frame_bytes) = $header =~ /\A([0-9]{6}):\z/;
my $response_bytes = '';
while (length($response_bytes) < $frame_bytes) {
  my $read = sysread $client_socket, my $part, $frame_bytes - length($response_bytes);
  die 'server closed before complete response frame' unless defined($read) && $read > 0;
  $response_bytes .= $part;
}
is(length($response_bytes), 0 + $frame_bytes, 'Unicode response frame length counts UTF-8 bytes');
my $response = decode('UTF-8', $response_bytes, 1);
my @results = Test::FitNesse::Slim::List->new($response)->list;
is_deeply(\@results, [['i', 'OK'], ['m', 'OK'], ['c', $payload]],
  'supplementary Unicode argument survives request and response serialization');

close $client_socket;
