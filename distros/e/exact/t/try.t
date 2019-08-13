use Test::Most tests => 2;

BEGIN {
    use_ok( 'exact', 'noautoclean' );
}

lives_ok(
    sub {
        try {
            1;
        }
        catch {
            1;
        };
    },
    'try',
);
