#!perl

use strict;
use warnings;
use Test::More 0.98;

use Array::IntSpan;
use Tie::Array::IntSpan;

my $intspan = Array::IntSpan->new([2,4,"A"],[6,7,"B"]);
tie my @ary, "Tie::Array::IntSpan", $intspan;

subtest "FETCH, FETCHSIZE" => sub {
    is_deeply([@ary], [undef,undef,"A","A","A",undef,"B","B"]);
};

subtest "STORE" => sub {
    $ary[9] = "C";
    is_deeply([@ary], [undef,undef,"A","A","A",undef,"B","B",undef,"C"]);
    $ary[2] = "a";
    is_deeply([@ary], [undef,undef,"a","A","A",undef,"B","B",undef,"C"]);
};

subtest "EXISTS" => sub {
    ok(!exists $ary[0]);
    ok( exists $ary[2]);
};

subtest "DELETE" => sub {
    delete $ary[2];
    is_deeply([@ary], [undef,undef,undef,"A","A",undef,"B","B",undef,"C"]);
};

subtest "PUSH" => sub {
    push @ary, "D", "E";
    is_deeply([@ary], [undef,undef,undef,"A","A",undef,"B","B",undef,"C","D","E"]);
};

subtest "CLEAR" => sub {
    @ary = ();
    is_deeply([@ary], []);
};

done_testing;
