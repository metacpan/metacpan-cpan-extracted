#!/usr/bin/perl -w
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More tests => 8;
use WWW::Webrobot::TestplanRunner;

my $hoa = { hh => [ qw(aa bb cc) ], gg => "GG", ii => [ qw(DD EE) ] };

my @test_data = (
    [ "array", [ qw(aa bb cc) ] ],
    [ "list of lists", [ qw(aa bb cc), [ qw(AA BB) ], "CC", [ qw(DD EE) ] ] ],
    [ "hash", { qw(hh HH gg GG) } ],
    [ "array of hash", [ qw(aa bb cc) ], { qw(hh HH gg GG) }, "CC" ],
    [ "hash of array", $hoa ],
);


foreach (@test_data) {
    my ($title, $tree) = @$_;
    is_deeply($tree, WWW::Webrobot::TestplanRunner::clone_me($tree), $title);
}

my $clone_hoa = WWW::Webrobot::TestplanRunner::clone_me($hoa);
$clone_hoa->{ii}->[1] = "miss";
is($hoa->{ii}->[1], "EE", "changed cloned value, assert original value");
isnt($hoa->{ii}->[1], $clone_hoa->{ii}->[1], "assert not cloned value");
$hoa->{ii}->[1] = "miss";
is($hoa->{ii}->[1], $clone_hoa->{ii}->[1], "changed original value, assert equal in cloned structure");



1;
