#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use_ok 'Types::Dist';

Types::Dist->import('DistFQ');

my $sub = DistFQ();

my @good = qw(Test-2 Test-3.1 A-0.01 A-B-C-3 Test-v2 Test-v3.1 A-v0.01 A-B-C-3);
my @bad  = (undef, qw/test 2.2.x 2.x 2.0.0 31.0.0 13.13.13 v2 v2.1 v2.001 v3.1.3.3 20001.1 1 2 1.2 Test2/);

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
