use strict;
use warnings;
use Test::More tests => 4;
use Win32::Pipe;

my $pipe_name = "Win32-Pipe-Test-$$-" . time;

my $server = Win32::Pipe->new($pipe_name);
isa_ok($server, 'Win32::Pipe', 'server pipe constructed');

my $size = $server->BufferSize;
ok($size > 0, "BufferSize returns positive value (got $size)");

my $new_size = $server->ResizeBuffer(4096);
is($new_size, 4096, 'ResizeBuffer returns the new size');

is($server->BufferSize, 4096, 'BufferSize reflects the resize');

$server->Close;
