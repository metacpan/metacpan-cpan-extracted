use strict;
use warnings;

use Test::More;

our @DONE :shared;   # Referenced outside this file

$SIG{'KILL'} = sub {
    $DONE[threads->tid()] = 1;
    threads->exit();
};


our %CHECKER :shared;   # Referenced outside this file

my $DEBUG = 0;   # Set true to debug

sub uncheck
{
    my $tid = shift;
    lock(%CHECKER);
    if (delete($CHECKER{$tid})) {
        diag("$tid cleared") if $DEBUG;
    } else {
        diag("$tid not set") if $DEBUG;
    }
}


sub probe
{
    lock(%CHECKER);
    return exists($CHECKER{shift()});
}


sub checker
{
    my $tid = threads->tid();
    while (1) {
        uncheck($tid);
        pause();
    }
}


sub pause
{
    select(undef, undef, undef, 0.25*rand());
}


sub check {
    my ($thr, $state, $line) = @_;
    my $tid = $thr->tid();

    pause();
    {
        lock(%CHECKER);
        delete($CHECKER{$tid});
        if (exists($CHECKER{$tid})) {
            ok(0, "BUG: \$CHECKER{$tid} not deleted");
        }
        $CHECKER{$tid} = $tid;
        diag("$tid set") if $DEBUG;
    }

    if ($state eq 'running') {
        for (1..100) {
            pause();
            last if (! probe($tid));
        }
        ok(! probe($tid), "Thread $tid $state (line $line)");
    } else {
        for (1..5) {
            pause();
            last if (! probe($tid));
        }
        ok(probe($tid), "Thread $tid $state (line $line)");
    }
}


sub make_threads
{
    my $nthreads = shift;
    my @threads;
    push(@threads, threads->create('checker')) for (1..$nthreads);
    is(scalar(threads->list()), $nthreads, 'Threads created');
    return @threads;
}

1;
