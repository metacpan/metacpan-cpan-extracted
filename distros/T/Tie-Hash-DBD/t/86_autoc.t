#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";

my %hash;
my $DBD = "Firebird";
cleanup ($DBD);
my $tbl = "t_tie_86_$$"."_persist";
eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD), { tbl => $tbl } };

tied %hash or plan_fail ($DBD);

ok (tied %hash,				"Hash tied");
ok ((tied %hash)->{dbh}{AutoCommit},    "AutoCommit ON");

untie %hash;
cleanup ($DBD);

done_testing;
