use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
  use_ok 'Win32::Pipe::PP';
}

my $pipe = Win32::Pipe->new("testpipe_ipc", 0);
ok($pipe, 'Pipe object created');

# Check IPC compatibility
ok($pipe->can('get_Win32_IPC_HANDLE'), 'get_Win32_IPC_HANDLE exists');
ok($pipe->get_Win32_IPC_HANDLE, 'Returns valid handle');

SKIP: {
  skip 'Win32::IPC not installed', 1 unless eval q( use Win32::IPC; !$@ );

  # Test wait_any compatibility (structurally only, no real signal)
  my $index = Win32::IPC::wait_any([$pipe], 100);
  ok(!defined $index, 'wait_any returns undef on timeout');
};

done_testing;
