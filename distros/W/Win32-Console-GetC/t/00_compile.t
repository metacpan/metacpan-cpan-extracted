use strict;
use Test::More tests => 1;
skip if $^O ne 'MSWin32';
BEGIN { use_ok 'Win32::Console::GetC' }
