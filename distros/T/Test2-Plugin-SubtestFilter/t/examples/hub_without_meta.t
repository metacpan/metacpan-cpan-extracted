use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Subtest qw(subtest_streamed);
use Test2::Plugin::SubtestFilter;

# Regression test: when a hub in the stack does not have 'subtest_name'
# metadata (e.g., created by subtest_streamed / run_subtest which bypasses
# the SubtestFilter-overridden subtest), the subtest should still run
# without warnings (fail-safe behavior).
#
# Structure mirrors real-world usage (e.g., Giga-Usagi t/Feature/.../Callback.t):
#   subtest 'top'                    <- overridden subtest (filter target)
#     subtest_streamed 'wrapper'     <- NOT overridden (no meta)
#       subtest 'inner_foo'          <- overridden subtest (filter target)
#       subtest 'inner_bar'          <- overridden subtest (filter target)
#         subtest 'deep'             <- overridden subtest (filter target)
#   subtest 'other'                  <- overridden subtest (filter target)

subtest 'top' => sub {
    subtest_streamed 'wrapper' => sub {
        subtest 'inner_foo' => sub {
            ok 1, 'foo test';
        };

        subtest 'inner_bar' => sub {
            ok 1, 'bar test';

            subtest 'deep' => sub {
                ok 1, 'deep test';
            };
        };
    };
};

subtest 'other' => sub {
    ok 1, 'other test';
};

done_testing;
