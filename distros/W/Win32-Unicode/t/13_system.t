use strict;
use warnings;
use Test::More;

use Win32::Unicode::Process;

ok !systemW 'echo hoge > nul';

done_testing;
