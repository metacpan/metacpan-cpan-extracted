use strict;
use warnings;
use Test::More tests => 7;
use FindBin;
use Win32::Pipe;

my $pipe_name = "Win32-Pipe-Test-$$-" . time;
my $client_path = "\\\\.\\pipe\\$pipe_name";

my $server = Win32::Pipe->new($pipe_name);
isa_ok($server, 'Win32::Pipe', 'server pipe constructed');

my $client_script = "$FindBin::Bin/02-roundtrip-client.pl";
my $pid = system(1, $^X, '-Mblib', $client_script, $client_path);
ok($pid > 0, "spawned client subprocess (pid $pid)");

ok($server->Connect, 'server accepted connection');
ok($server->Write('ping'), 'server wrote ping');

my $reply = $server->Read;
is($reply, 'pong', 'server received pong from client');

ok($server->Disconnect, 'server disconnected');
$server->Close;

waitpid($pid, 0);
is($? >> 8, 0, 'client subprocess exited cleanly');
