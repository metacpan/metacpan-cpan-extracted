use strict;
use warnings;
use Test::More tests => 7;
use FindBin;
use IPC::Open3;
use Win32::Pipe;

my $pipe_name = "Win32-Pipe-Test-$$-" . time;
my $client_path = "\\\\.\\pipe\\$pipe_name";

my $server = Win32::Pipe->new($pipe_name);
isa_ok($server, 'Win32::Pipe', 'server pipe constructed');

my $client_script = "$FindBin::Bin/02-roundtrip-client.pl";
# Cygwin perl does not support system(1, ...), so start the client
# with open3, which also returns without waiting for it.
my $pid = open3('<&STDIN', '>&STDERR', undef,
    $^X, '-Mblib', $client_script, $client_path);
ok($pid > 0, "spawned client subprocess (pid $pid)");

ok($server->Connect, 'server accepted connection');
ok($server->Write('ping'), 'server wrote ping');

my $reply = $server->Read;
is($reply, 'pong', 'server received pong from client');

is($server->Disconnect, 1, 'server disconnected');
$server->Close;

waitpid($pid, 0);
is($? >> 8, 0, 'client subprocess exited cleanly');
