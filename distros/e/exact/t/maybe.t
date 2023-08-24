use Test2::V0;
use exact;

my $data;

ok(
    lives {
         $data = {
            answer        => 42,
            thx           => 1138,
            maybe special => undef,
            maybe extra   => 'readall',
        };
    },
    'maybe calls',
) or note $@;

is(
    $data,
    {
        answer => 42,
        thx    => 1138,
        extra  => 'readall',
    },
    'maybe data',
);

done_testing;
