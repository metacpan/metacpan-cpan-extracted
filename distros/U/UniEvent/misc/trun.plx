#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use MyTest;
use Test::Catch;
use XLog;

$SIG{PIPE} = 'IGNORE';
my @vars = @ARGV;
my $tname = shift(@vars) or die "usage: $0 <test name> [<variations>...]";
my $cnt = 1;
if ($vars[0] and $vars[0] =~ /^\d+$/) {
    $cnt = shift @vars;
}
alarm(0);

if ($ENV{LOGGER}) {
    XLog::set_logger(sub { say $_[1] });
    XLog::set_level(XLog::DEBUG, "UniEvent");
    XLog::set_level(XLog::INFO, "UniEvent::SSL");
}

if (@vars) {
    variate_catch($tname, @vars) for (1..$cnt);
} else {
    catch_run($tname) for (1..$cnt);
}

done_testing();
