#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use Types::RENEEB qw(OTRSVersion);

my $Version = OTRSVersion();

my @good = qw(2.0.0 31.0.0 13.13.13);
my @bad  = (undef, qw/test 0 2 4.5 2.2.x 2.x/);

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
