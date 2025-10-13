use strict;
use warnings;

use Test::More tests => 13;

BEGIN {
  use_ok 'Win32::Pipe::PP';
}

my $pipe = Win32::Pipe->new("testpipe_api", 0);
ok($pipe, 'Pipe created');

foreach my $method (qw(Connect Read Write Disconnect Close Error ResizeBuffer 
  BufferSize Info Credit Center)
) {
  ok($pipe->can($method), "$method method exists");
}

done_testing;
