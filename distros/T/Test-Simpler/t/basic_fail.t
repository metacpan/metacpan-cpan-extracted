#! /usr/bin/env polyperl
use 5.014; use warnings; use autodie;

use Test::More;
use Test::Simpler tests => 7;

TODO:{
    local $TODO = 'These are supposed to fail';

    {
        my $expected = [ { a => 1, b => 2, c => 3 }, 'c' ];
        my @got      = ( { a => 1, b => 2 }, 'c' );

        ok
            @got
            ~~
            $expected

        => 'Test 1';
    }

    {
        my @got = ( { a => 1, b => 2222 }, 'c' );

        ok $got[0]{b} == 2
    }

    {
        no warnings 'uninitialized';
        my $expected = qr/[abc]/;
        my $got = [ { a => 1, b => 2 }, 'c' ];

        ok $got->[0]{'B'} =~ $expected
        => 'Test 3';
    }

    {
        my $got = 1.5;

        ok +(0 < $got && $got < 1), 'Test 4';
    }

    {
        sub got { length shift }

        ok( got(q{}) != 0 );
    }

    {
        { package Quote; sub asx_code { 'QBE' } }
        my $qbe = bless {}, 'Quote';

        my $methname = 'asx_code';

        ok $qbe->asx_code    eq 'EBQ' => 'get asx_code';
        ok $qbe->$methname() eq 'EBQ' => 'get methname';
    }
}
