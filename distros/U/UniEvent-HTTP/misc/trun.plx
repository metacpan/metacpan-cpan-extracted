#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use MyTest;
use Test::More;
use Test::Catch;

$SIG{PIPE} = 'IGNORE';
my @vars = @ARGV;
my $tname = shift(@vars) or die "usage: $0 <test name> [count]";
my $cnt = 1;
if ($vars[0] and $vars[0] =~ /^\d+$/) {
    $cnt = shift @vars;
}

catch_run($tname) for (1..$cnt);

done_testing();

