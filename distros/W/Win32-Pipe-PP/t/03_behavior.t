use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
  use_ok 'Win32::Pipe::PP';
}

my $pipe = Win32::Pipe->new("testpipe_behavior", 0);
ok($pipe->Disconnect, 'Disconnect succeeds');
ok($pipe->Close, 'Close succeeds');

my ($code, $msg) = $pipe->Error;
is($code, 0, 'No error after valid operations');

done_testing;
