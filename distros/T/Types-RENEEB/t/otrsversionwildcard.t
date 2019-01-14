#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use Types::RENEEB qw(OTRSVersionWildcard);

my $Version = OTRSVersionWildcard();

my @good = qw(2.0.0 2.1.x 31.0.0 31.x 13.0.x 13.13.13);
my @bad  = (undef, qw/test 0 2 4.5/);

for my $good ( @good ) {
    ok $Version->($good);
}

for my $bad ( @bad ) {
    my $error;
    eval { $Version->($bad); 1; } or $error = $@;

    my $re = defined $bad ? qr/Value ".*?" did not pass/ : qr/Undef did not pass/;
    like $error, $re, sprintf "Bad value: '%s'", $bad // '<undef>';
}

done_testing();
