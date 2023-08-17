#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use XLog;
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

if ($ENV{LOGGER}) {
    XLog::set_logger(XLog::Console->new);
    XLog::set_level(XLog::DEBUG);
}

test_catch($tname) for (1..$cnt);

done_testing();
