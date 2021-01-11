use Test2::V0;
use exact -noautoclean;

ok(
    lives {
        try {
            1;
        }
        catch {
            1;
        };
    },
    'try',
) or note $@;

done_testing;
