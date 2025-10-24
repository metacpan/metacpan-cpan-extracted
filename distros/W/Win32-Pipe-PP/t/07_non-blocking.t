use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
  use_ok 'Win32::Pipe::PP';
}

my $pipename = 'testpipe-' . $$ . '-' . int(rand(1_000_000));
my $bufsize;

my $server = Win32::Pipe->new($pipename)
  or die "Server creation failed: " . Win32::Pipe::PP::Error();
$server->blocking(0);
is($server->blocking(), 0, "Mode set to non-blocking");
$bufsize = $server->BufferSize();
ok($server, "Server object created (bufsize=$bufsize)");

my $client = Win32::Pipe->new("\\\\.\\pipe\\$pipename")
  or die "Client creation failed: " . Win32::Pipe::PP::Error();
$bufsize = $client->BufferSize();
ok($client, "Client object created (bufsize=$bufsize)");

ok($server->Connect(), "Server connected");

my $msg = "Hello";
ok($client->Write($msg), "Client wrote data");

my $can_read = $server->wait(2000);
ok($can_read, "Server detected data");

my $data = $server->Read();
is($data, $msg, "Server read correct data");

$client->Close();
$server->Disconnect();
$server->Close();

done_testing();
