use 5.014;
use warnings;
use autodie;

use Test::Simpler tests => 4;

{
    my @got = ( { a => 1, b => 2 }, 'c' );

    ok $got[0]{b} == 2
}

{
    my $expected = qr/[abc]/;
    my $got = [ { a => 'a', b => 'b' }, 'c' ];

    ok $got->[0]{lc 'B'} =~ $expected
       => 'Test 2';
}

{
    my $got = 0.5;

    ok +(0 < $got && $got < 1), qq<Test 3>;
}

{
    sub got { length shift }

    ok( got(q{b}) != 0 );
}
