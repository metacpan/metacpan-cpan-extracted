use Test2::V0;
use exact;

ok(
    lives {
        try {
            1;
        }
        catch ($e) {
            1;
        };
    },
    'try',
) or note $@;

done_testing;
