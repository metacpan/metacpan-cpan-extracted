use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
  # Drop-in replacement for Win32::Pipe
  use_ok 'Win32::Pipe::PP';
}

# Logical name used by the server when creating the pipe (no \\.\pipe\ prefix 
# here)
my $pipename = 'testpipe-' . $$ . '-' . int(rand(1_000_000));

# Fully qualified client path; clients connect to \\.\pipe\<name>
my $client_path  = '\\\\.\\pipe\\' . $pipename;

# Server: create the pipe instance (no Connect yet)
my $srv = Win32::Pipe->new($pipename);
ok($srv, 'Server: Pipe object created');

# Buffer checks (default and after resize)
my $size = Win32::Pipe::PP::BUFFER_SIZE;
is($srv->BufferSize, $size, "Server: Default buffer size ($size)");
$srv->ResizeBuffer(256);
ok($srv->BufferSize >= 256, 'Server: Resized buffer size');

# Client: open the pipe; retry for robustness
my $cli;
for ( 1 .. 100 ) {
  # Client connects by opening \\.\pipe\<name>
  $cli = Win32::Pipe->new($client_path);
  last if $cli;
  # Give the server a moment to get ready (50 ms)
  select(undef, undef, undef, 50/1000);
}
ok($cli, 'Client: Pipe object created');

# Server: Connect (may return ERROR_PIPE_CONNECTED (535) if client already 
# connected)
my $connected = $srv->Connect;
unless ($connected) {
  my ($ecode, $emsg) = Win32::Pipe->Error();
  # Windows allows a client to connect between CreateNamedPipe and 
  # ConnectNamedPipe. If that happens, ConnectNamedPipe fails and 
  # GetLastError() == ERROR_PIPE_CONNECTED (535), which should be treated as a 
  # successful connection.
  $connected = 1 if defined $ecode && $ecode == 535;
}
ok($connected, 'Server: Connect succeeded (or ERROR_PIPE_CONNECTED handled)');

# Client -> Server: send a message
my $ok_cli = $cli->Write("Hello World");
ok($ok_cli, 'Client: Write "Hello World" succeeded');

# Server: read the client message
my $data = $srv->Read();
is($data, 'Hello World', 'Server: Read returns expected data');

# Server -> Client: send an ACK back to the client
my $ok_srv = $srv->Write("ACK: $data");
ok($ok_srv, 'Server: ACK Write succeeded');

# Client: read the ACK from the server
my $ack = $cli->Read();
is($ack, 'ACK: Hello World', 'Client: Read ACK returns expected data');

# Check last error after successful operations (should be 0 / no message)
my ($code, $msg) = Win32::Pipe->Error();
is($code, 0, 'Server: No error code after successful ops');
ok(!$msg, 'Server: No error message');

# Cleanup on server end
ok($cli->Disconnect, 'Client: Disconnect succeeded');
ok($srv->Disconnect, 'Server: Disconnect succeeded');

done_testing;
