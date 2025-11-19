use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
  use_ok 'Win32API::Console';
}

ok(eval { Win32API::Console::GetOSVersion() }, 'GetOSVersion()');

done_testing;
