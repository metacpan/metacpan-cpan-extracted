use Test::More tests => 3;

use qbit;

is_deeply(
    {
        hash_transform(
            {
                a => 1,
                b => 2,
                c => 3,
                d => 4
            },
            [qw(a c d)],
            {d => 'e'}
        )
    },
    {
        a => 1,
        c => 3,
        e => 4
    },
    "hash_transform"
);

is_deeply(
    {
        hash_transform(
            {
                a => 1,
                b => 2,
                c => 3,
                d => 4
            },
            [qw(a c)],
            {d => 'e'}
        )
    },
    {
        a => 1,
        c => 3,
        e => 4
    },
    "hash_transform"
);

my %h1 = (a => 1, b => 5, c => 10);
push_hs(%h1, {c => 15, d => 20});
is_deeply(\%h1, {a => 1, b => 5, c => 15, d => 20}, 'Check push_hs');
