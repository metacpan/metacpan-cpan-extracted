#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Wasm::Wasm3 ();

my @version_nums = Wasm::Wasm3::M3_VERSION;

cmp_deeply(
    \@version_nums,
    [
        map { re( qr<\A[0-9]+\z> ) } 1 .. 3,
    ],
    'M3_VERSION() returns 3 uints',
);

like(
    Wasm::Wasm3::M3_VERSION_STRING,
    qr<\A
        .*$version_nums[0].*\.
        .*$version_nums[1].*\.
        .*$version_nums[2].*
    \z>x,
    'M3_VERSION_STRING()',
);

{
    my $env = Wasm::Wasm3->new();

    isa_ok($env, 'Wasm::Wasm3', 'new() result');
}

{
    my $rt = Wasm::Wasm3->new()->create_runtime(1234);
    isa_ok($rt, 'Wasm::Wasm3::Runtime', 'create_runtime() result');
}

eval { Wasm::Wasm3->new()->create_runtime(0xffff_ffff + 1) };
my $err = $@;
ok( $err, 'create_runtime() fails if stack size is too big' );

done_testing;
