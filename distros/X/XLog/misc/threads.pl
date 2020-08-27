use 5.012;
use XLog;
use threads;

{
    package Epta;
    sub CLONE {
        say "CLONE";
    }
}

XLog::set_logger(sub {
    say "ARGS: @_";
});

our $a = bless {}, 'Epta';

my $thr = threads->create(sub {
    say "thread created";
});

$thr->join;

say "JOINED";

XLog::epta();
