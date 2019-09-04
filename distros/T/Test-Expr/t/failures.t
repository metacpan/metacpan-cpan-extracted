#! /usr/bin/env perl

use 5.014;
use warnings;
use experimentals;

#use Keyword::Declare {debug=>1};
use Test::Expr;

sub foo { 255 };
my $foo = foo();
my $bar = 1;
my $expected = 2**8;

TODO: {
    local $TODO = 'Testing for failures';

    ok $foo  == $expected; #Great report i know what I got and what I expected
    ok $foo  == length($expected); #confusing report, I care to see length($expected) not $expected in the report
    ok $foo  == 2**8; #Less than awesome report since I do not immediately see what is the expected value, I have to do the calculation manually
    ok foo() == 2**8; #No report at all... I have no idea what I got nor what I expected. (This is my biggest issue)

    ok !foo($foo == $expected);

    ok rand == 1;

    ok "2" == 1;

    ok not $foo != $expected;

    ok not ($foo != $expected);

    ok ($foo != $foo) == length($bar);

}

done_testing();
