#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::GetVolatileData;
plan tests => 11;

SKIP: {
    my $test = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt')
        or skip 'Failed to fetch volatile data; error is: '
        . ( defined $Test::GetVolatileData::ERROR ? $Test::GetVolatileData::ERROR : '[undefined]'), 1;

    like($test, qr/test\d/, 'get_data() without any extra args');
}

SKIP: {
    my @test = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt',
        num => 1,
    ) or skip 'Failed to fetch volatile data; error is: '
        . ( defined $Test::GetVolatileData::ERROR ? $Test::GetVolatileData::ERROR : '[undefined]'),  2;

    is(
        scalar(@test),
        1,
        q{get_data('...', num => 1, returns two data pieces) },
    );

    is(
        scalar(grep /\Atest\d\z/, @test),
        1,
        q{get_data('...', num => 1, returns proper data pieces },
    );
}


SKIP: {
    my @test = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt',
        num => 2,
    ) or skip 'Failed to fetch volatile data; error is: '
        . ( defined $Test::GetVolatileData::ERROR ? $Test::GetVolatileData::ERROR : '[undefined]'),  2;

    is(
        scalar(@test),
        2,
        q{get_data('...', num => 2, returns two data pieces) },
    );

    is(
        scalar(grep /\Atest\d\z/, @test),
        2,
        q{get_data('...', num => 2, returns proper data pieces },
    );
}

SKIP: {
    my @test = get_data('http://zoffix.com/CPAN/Test-GetVolatileData.txt',
        num => 2000,
    ) or skip 'Failed to fetch volatile data; error is: '
        . ( defined $Test::GetVolatileData::ERROR ? $Test::GetVolatileData::ERROR : '[undefined]'), 2;

    is(
        scalar(@test),
        5,
        q{get_data('...', num => OVERLY_LARGE, returns all data pieces) },
    );

    is(
        scalar(grep /\Atest\d\z/, @test),
        5,
        q{get_data('...', num => OVERLY_LARGE, returns proper data pieces },
    );
}


my $must_be_undef = get_data('http://zoffix.com/CPAN/FAIL.txt');

is( $must_be_undef, undef, 'Errored out return must be undef');
diag '[Must get this error] Error is '
    . ( defined $Test::GetVolatileData::ERROR
        ? $Test::GetVolatileData::ERROR : '[undefined]'
    );
like( $Test::GetVolatileData::ERROR, qr/Network error/,
    'errored out return must set ::ERROR',
);

my $must_be_undef2 = get_data('http://zoffix.com/CPAN/FAIL.txt', num => 2 );
diag '[Must get this error] Error is '
    . ( defined $Test::GetVolatileData::ERROR
        ? $Test::GetVolatileData::ERROR : '[undefined]'
    );
is( $must_be_undef2, undef, 'Errored out return must be undef');
like( $Test::GetVolatileData::ERROR, qr/Network error/,
    'errored out return must set ::ERROR (when ``num`` is set)',
);