#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

sub autoctests {
    my ($DBD, $t) = @_;

    my %hash;
    cleanup ($DBD);

    my $rnd = sprintf "%d_%04d", $$, (time + int rand 10000) % 10000;
    my $tbl = "t_tie_${t}_${rnd}_persist";

    eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD), { tbl => $tbl } };

    tied %hash or plan_fail ($DBD);

    ok (tied %hash,				"Hash tied");
    ok ((tied %hash)->{dbh}{AutoCommit},    "AutoCommit ON");

    untie %hash;
    cleanup ($DBD);
    } # autoctests

1;
