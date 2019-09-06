#! /usr/bin/env perl

use 5.012;
use warnings;
use experimentals;

use Test::Expr;

sub foo { 255 };
my $foo = foo();
my $bar = 1;
my $expected = 2**8;

sub rx { qr/whatever/ }

TODO: {
    local $TODO = 'Testing for failures';

    ok $foo  == $expected;
    ok $foo  == length($expected);
    ok $foo  == 2**8;
    ok foo() == 2**8;

    ok !foo($foo == $expected);

    ok rand == 1;

    ok "2" == 1;

    ok not $foo != $expected;

    ok not ($foo != $expected);

    ok ($foo != $foo) == length($bar);

    ok foo('bar') == 256;

    ok foo() =~ qr/whatever/;
    ok foo() =~   /whatever/;
    ok foo() =~  m/whatever/;

    ok foo() =~  rx();

    ok foo() =~ s/whatever/et cetera/;

    ok foo() =~ tr/A-Z/a-z/;
    ok foo() =~  y/A-Z/a-z/;

    ok foo() =~  m/what $foo ever$/;
}

done_testing();
