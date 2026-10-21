use strict;
use warnings;
use Test::More tests => 9;
use Win32::Pipe;

# The methods hide which values an XSUB returns, so call the XSUBs directly
# and check that a value listed before the call is still in the result.

my $pipe_name = "Win32-Pipe-Test-$$-" . time;

my @create = (1, Win32::Pipe::PipeCreate($pipe_name, Win32::Pipe::DEFAULT_WAIT_TIME()));
is(scalar @create, 2, 'PipeCreate returns one value');
my $pipe = $create[-1];

my @resize = (1, Win32::Pipe::PipeResizeBuffer($pipe, 4096));
is_deeply(\@resize, [1, 4096], 'PipeResizeBuffer');
my @size = (1, Win32::Pipe::PipeBufferSize($pipe));
is_deeply(\@size, [1, 4096], 'PipeBufferSize');
my @error = (1, Win32::Pipe::PipeError($pipe));
is_deeply(\@error, [1, 0, ''], 'PipeError');
my @usage = (1, Win32::Pipe::PipeBufferSize());
is_deeply(\@usage, [1, 999, "usage: BufferSize(\$PipeHandle);\n"], 'usage error');

my @info = (1, Win32::Pipe::Info());
is(scalar @info, 8, 'Info returns seven values');

my @close = (1, Win32::Pipe::PipeClose($pipe));
is_deeply(\@close, [1, 0], 'PipeClose');

my $server = Win32::Pipe->new("$pipe_name-read");
ok(!defined $server->Read, 'Read without a client returns undef');
ok($server->{'Pipe'}, 'failed Read leaves the pipe handle alone');
$server->Close;
