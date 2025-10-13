use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'Win32::Pipe::PP';
}

my $pipe = Win32::Pipe->new("testpipe_load", 0);
ok($pipe, 'Pipe created');

done_testing;
