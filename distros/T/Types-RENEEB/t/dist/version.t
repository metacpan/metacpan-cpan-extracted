#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;

use_ok 'Types::Dist';

Types::Dist->import('DistVersion');

my $sub = DistVersion();

my @good = qw(2.0.0 31.0.0 13.13.13 v2 v2.1 v2.001 v3.1.3.3 20001.1 1 2 1.2);
my @bad  = (undef, qw/test 2.2.x 2.x/);

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
