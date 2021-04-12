#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use XLog;
use MyTest;
use Test::Catch;

$SIG{PIPE} = 'IGNORE';
my @vars = @ARGV;
my $tname = shift(@vars) or die "usage: $0 <test name> [<variations>...]";
my $cnt = 1;
if ($vars[0] and $vars[0] =~ /^\d+$/) {
    $cnt = shift @vars;
}
alarm(0);

if ($ENV{LOGGER}) {
    require XLog;
    XLog::set_logger(XLog::Console->new);
    XLog::set_format("%f:%l: %m");
    XLog::set_level(XLog::DEBUG(), "UniEvent");
    XLog::set_level(XLog::INFO(), "UniEvent::SSL");
}

if (@vars) {
    variate_catch($tname, @vars) for (1..$cnt);
} else {
    catch_run($tname) for (1..$cnt);
}

done_testing();
