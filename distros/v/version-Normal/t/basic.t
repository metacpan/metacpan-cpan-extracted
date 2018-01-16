
use Test::More 0.88;
use version::Normal;

our @TESTS = (
    {   input   => '0.4',
        normal2 => 'v0.400',
        normal3 => '0.400.0',
    },
    {   input   => 'v1.0.0',
        normal2 => 'v1.0',
        normal3 => '1.0.0',
    },
    {   input   => 'v1.0.0.0',
        normal2 => 'v1.0',
        normal3 => '1.0.0',
    },
    {   input   => '0.1',
        normal2 => 'v0.100',
        normal3 => '0.100.0',
    },
    {   input   => 'v0.1',
        normal2 => 'v0.1',
        normal3 => '0.1.0',
    },
    {   input   => 'v1',
        normal2 => 'v1.0',
        normal3 => '1.0.0',
    },
    {   input   => '0.010',
        normal2 => 'v0.10',
        normal3 => '0.10.0',
    },
    {   input   => '1.010',
        normal2 => 'v1.10',
        normal3 => '1.10.0',
    },
    {   input   => '0.3.10',
        normal2 => 'v0.3.10',
        normal3 => '0.3.10',
    },
    {   input   => 'v0.0.0.0',
        normal2 => 'v0.0',
        normal3 => '0.0.0',
    },
    {   input   => 'v0.1.0.0',
        normal2 => 'v0.1',
        normal3 => '0.1.0',
    },
);

for my $t (@TESTS) {
    my $input     = $t->{input};
    my $expected2 = $t->{normal2};
    my $expected3 = $t->{normal3};

    my $v       = version->parse($input);
    my $normal2 = $v->normal2;
    my $normal3 = $v->normal3;

    is( $normal2, $expected2, qq{NORMAL2('$input') = '$expected2'} );
    ok( $v == version->parse($normal2), qq{NORMAL2('$input') equiv '$input'} );

    is( $normal3, $expected3, qq{NORMAL3('$input') = '$expected2'} );
    ok( $v == version->parse($normal3), qq{NORMAL3('$input') equiv '$input'} );
}

done_testing;
