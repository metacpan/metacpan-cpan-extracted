#!/usr/bin/env perl
use 5.012;
use lib 't/lib';
use MyTest;
use Test::Catch;
use Panda::Lib::Logger;

$SIG{PIPE} = 'IGNORE';
my @vars = @ARGV;
my $tname = shift(@vars) or die "usage: $0 <test name> [<variations>...]";
my $cnt = 1;
if ($vars[0] and $vars[0] =~ /^\d+$/) {
    $cnt = shift @vars;
}
alarm(0);

if ($ENV{LOGGER}) {
    Panda::Lib::Logger::set_native_logger(sub {
        my ($level, $code, $msg) = @_;
        say "$level $code $msg";
    });
    Panda::Lib::Logger::set_log_level(Panda::Lib::Logger::LOG_DEBUG, "UniEvent");
    Panda::Lib::Logger::set_log_level(Panda::Lib::Logger::LOG_DEBUG, "UniEvent::Backend");
    Panda::Lib::Logger::set_log_level(Panda::Lib::Logger::LOG_INFO, "UniEvent::SSL");
}

if (@vars) {
    variate_catch($tname, @vars) for (1..$cnt);
} else {
    catch_run($tname) for (1..$cnt);
}

done_testing();
Panda::Lib::Logger::set_log_level(Panda::Lib::Logger::LOG_CRITICAL); #turn logger off, it does not work in perl destroy phase

