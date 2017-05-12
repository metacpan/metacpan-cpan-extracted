use strict;
use warnings;

# this test demonstrates that we can capture warnings and test its contents,
# and that captured warning will not fail the had-no-warnings test which is
# added at the end

use Test::More tests => 3;
use Test::Warnings ':all';

pass('yay!');
like(warning { warn "oh noes!" }, qr/^oh noes/, 'we warned');
