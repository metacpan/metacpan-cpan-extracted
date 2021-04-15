use Test2::Plugin::Cover;
use Test2::V0;

use IPC::Cmd qw/can_run/;

is(
    warnings { can_run('git') },
    [],
    "No warnings"
);

done_testing;
