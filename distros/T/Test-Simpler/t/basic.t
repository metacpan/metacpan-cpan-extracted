#! /usr/bin/env polyperl
use 5.014; use warnings; use autodie;

use Test::Simpler tests => 5;

{
    my $expected = [ { a => 1, b => 2 }, 'c' ];
    my @got      = ( { a => 1, b => 2 }, 'c' );

    ok
        @got
        ~~
        $expected

    => 'Test 1';
}

{
    my @got = ( { a => 1, b => 2 }, 'c' );

    ok $got[0]{b} == 2
}

{
    my $expected = qr/[abc]/;
    my $got = [ { a => 'a', b => 'b' }, 'c' ];

    ok $got->[0]{lc 'B'} =~ $expected
       => 'Test 3';
}

{
    my $got = 0.5;

    ok +(0 < $got && $got < 1), qq<Test 4>;
}

{
    sub got { length shift }

    ok( got(q{b}) != 0 );
}
