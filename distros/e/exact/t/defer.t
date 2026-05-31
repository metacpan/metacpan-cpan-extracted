use Test2::V0;
use exact;

ok( lives { defer { 1 } }, 'defer' ) or note $@;

done_testing;
