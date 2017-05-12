#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use lib 'lib';

for my $xt (glob('t/cases/*.xt')) {
    (my $expected = $xt) =~ s/\.xt\z/.expected/;
    my $cmd = "perl -Ilib $xt > $expected";
    system($cmd)==0 or die "ABORT\n";
}

for my $file (sort <eg/*.t>) {
    for my $reporter (qw(Spec TAP)) {
        for my $power (0, 1) {
            (my $outfile = $file) =~ s/\.t\z/-${reporter}-${power}.out/;
            my $cmd = "perl -Ilib $file > $outfile";
            local $ENV{KANTAN_REPORTER}=$reporter;
            local $ENV{KANTAN_NOOBSERVER} = $power ? 0 : 1;
            system($cmd)==0 or die "ABORT\n";
        }
    }
}

