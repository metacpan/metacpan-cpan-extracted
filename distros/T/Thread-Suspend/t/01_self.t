use strict;
use warnings;

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use threads;
use threads::shared;


### Preamble ###

our $nthreads;
BEGIN { $nthreads = 3; }
use Test::More 'tests' => 2 + 17 * $nthreads;


### Load module ###

use_ok('Thread::Suspend');


### Setup ###

use lib '.';
require 't/test.pl';

sub checker2
{
    no warnings 'once';

    my $tid = threads->tid();
    threads->self()->suspend();
    while (1) {
        {
            lock(%::CHECKER);
            delete($::CHECKER{$tid});
        }
        select(undef, undef, undef, 0.5*rand());
    }
}

my @threads;
push(@threads, threads->create('checker2')) for (1..$nthreads);
is(scalar(threads->list()), $nthreads, 'Threads created');
pause();


### Functionality testing ###

foreach my $thr (threads->is_suspended()) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'In suspend list');
}

while (my $thr = shift(@threads)) {
    my $tid = $thr->tid();

    is(scalar(threads->is_suspended()), scalar(@threads)+1, "Threads suspended");
    is(scalar(grep { $_ == $thr } threads->is_suspended()), 1, 'In suspend list');
    is($thr->is_suspended(), 1, "Thread $tid suspended");
    check($thr, 'stopped', __LINE__);

    $thr->suspend();
    is(scalar(threads->is_suspended()), scalar(@threads)+1, "Threads suspended");
    is(scalar(grep { $_ == $thr } threads->is_suspended()), 1, 'In suspend list');
    is($thr->is_suspended(), 2, "Thread $tid suspended twice");
    check($thr, 'stopped', __LINE__);

    $thr->resume();
    is(scalar(threads->is_suspended()), scalar(@threads)+1, "Threads suspended");
    is(scalar(grep { $_ == $thr } threads->is_suspended()), 1, 'In suspend list');
    is($thr->is_suspended(), 1, "Thread $tid still suspended");
    check($thr, 'stopped', __LINE__);

    $thr->resume();
    is(scalar(threads->is_suspended()), scalar(@threads), "Threads suspended");
    is(scalar(grep { $_ == $thr } threads->is_suspended()), 0, 'Not in suspend list');
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);

    # Cleanup
    $thr->kill('KILL')->join();
}

exit(0);

# EOF
