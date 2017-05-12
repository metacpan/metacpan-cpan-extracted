use strict;
use warnings;

use Test::More tests => 1;
use Test::Requires::Env;

local $ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
local $ENV{HOME} = '/home/zigorou';
local $ENV{TERM} = '/bin/bash';

test_environments(qw/PATH HOME TERM/);
test_environments( +{
    PATH => qr{/usr/bin},
    HOME => '/home/zigorou',
    TERM => qr{/bin/(?:tc|ba|z)sh},
} );

ok 'all test passed';

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
