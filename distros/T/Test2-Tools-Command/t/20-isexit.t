#!perl
#
# tests for is_exit

use Test2::V0 -no_srand => 1;
use Test2::Tools::Command;
use Test2::API 'intercept';

plan 9;

is_exit 0;
is_exit 24 << 8, 24;
is_exit 42 << 8, { code => 42, signal => 0, iscore => 0 }, "exit 42";
is_exit 42 << 8, { code => 1,  signal => 0, iscore => 0, munge_status => 1 };
is_exit 0,       { code => 0,  signal => 0, iscore => 0, munge_status => 1 };
is_exit 6 | 128, { code => 0, signal => 6, iscore => 1 };
is_exit 6 | 128, { code => 0, signal => 1, iscore => 1, munge_signal => 1 };
is_exit 0,       { code => 0, signal => 0, iscore => 0, munge_signal => 1 };

my $events = intercept { is_exit 0, { code => 0, signal => 0, iscore => 1 } };
is $events->state->{failed}, 1;
