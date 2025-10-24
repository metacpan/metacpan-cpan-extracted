use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok 'Win32::Pipe::PP';
}

my $pipe = Win32::Pipe->new("\\\\.\\pipe\\", 0);    # invalid Name
ok(!$pipe, 'Pipe creation fails');

my ($code, $msg) = Win32::Pipe->Error();
ok($code, 'Error code set');
like($msg, 
  qr/Name is too short|CreateFile failed|CreateNamedPipe failed/i,
  'Error message set'
);
$pipe = Win32::Pipe->new("testpipe_error", 0);
$pipe->Close;
ok(!$pipe->Write("data"), 'Write fails after close');

done_testing;
