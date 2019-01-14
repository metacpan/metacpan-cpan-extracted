#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use_ok 'Types::Dist';

Types::Dist->import('DistName');

my $sub = DistName();

my @good = qw(test Test test-Test Test-test one-two-three a-very-long-name-for-dists a z A B a-a A-a a-B A-A One-Two Test2 Test2-two Test-2 Test-two2);
my @bad  = (undef, qw/test.al 2a 1 4.5 2.2.x <test>/);

for my $good ( @good ) {
    ok $sub->($good);
}

for my $bad ( @bad ) {
    my $error;
    eval { $sub->($bad); 1; } or $error = $@;

    my $re = defined $bad ? qr/Value ".*?" did not pass/ : qr/Undef did not pass/;
    like $error, $re, sprintf "Bad value: '%s'", $bad // '<undef>';
}

done_testing();
