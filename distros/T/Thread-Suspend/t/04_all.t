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
use Test::More 'tests' => 84;


### Load module ###

use_ok('Thread::Suspend');


### Setup ###

use lib '.';
require 't/test.pl';

my @threads = make_threads($nthreads);


### Functionality testing ###

ok(! threads->is_suspended(), 'No threads suspended');
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}

# Test all threads

my @suspended = threads->suspend();
is(scalar(@suspended), scalar(@threads), 'Suspended threads');
foreach my $thr (@suspended) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'Thread suspended');
}

is(scalar(threads->is_suspended()), scalar(@threads), 'All threads suspended');
foreach my $thr (threads->is_suspended()) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'In suspend list');
}

foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 1, "Thread $tid suspended");
    check($thr, 'stopped', __LINE__);
}

is(scalar(threads->suspend()), scalar(@threads), 'Suspending again');
pause();
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 2, "Thread $tid suspended");
    check($thr, 'stopped', __LINE__);
}

is(scalar(threads->resume()), scalar(@threads), 'Resuming once');
pause();
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 1, "Thread $tid suspended");
    check($thr, 'stopped', __LINE__);
}

is(scalar(threads->resume()), scalar(@threads), 'Resuming again');
pause();
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}

# Test threads with extra suspends

is($threads[1]->suspend(), $threads[1], 'Suspend thread');
pause();
is(scalar(threads->is_suspended()), 1, '1 thread suspended');
check($threads[1], 'stopped', __LINE__);

@suspended = threads->suspend();
pause();
is(scalar(@suspended), scalar(@threads), 'Suspended threads');
foreach my $thr (@suspended) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'Thread suspended');
}
is(scalar($threads[0]->is_suspended()), 1, 'Thread suspended');
is(scalar($threads[1]->is_suspended()), 2, '1 thread suspended twice');
is(scalar($threads[2]->is_suspended()), 1, 'Thread suspended');
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    check($thr, 'stopped', __LINE__);
}

is(scalar(threads->resume()), scalar(@threads), 'Resuming threads');
pause();
is(scalar($threads[0]->is_suspended()), 0, 'Thread not suspended');
is(scalar($threads[1]->is_suspended()), 1, 'Thread suspended');
is(scalar($threads[2]->is_suspended()), 0, 'Thread not suspended');
check($threads[1], 'stopped', __LINE__);

is($threads[1]->resume(), $threads[1], 'Thread resumed');
pause();

foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}

# Test with detached threads

my $detached = $threads[1]->tid();
$threads[1]->detach();
ok($threads[1]->is_detached(), 'Thread detached');

@suspended = threads->suspend();
pause();
is(scalar(@suspended), scalar(@threads)-1, 'Suspended threads');
is(scalar(grep { $_ == $threads[0] } @suspended), 1, 'Thread suspended');
is(scalar(grep { $_ == $threads[2] } @suspended), 1, 'Thread suspended');
is(scalar($threads[1]->is_suspended()), 0, 'Thread not suspended');

is(scalar(threads->resume()), scalar(@threads)-1, 'Resuming threads');
pause();

foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}


### Cleanup ###

foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->kill('KILL'), $thr, 'Killing thread');
    no warnings 'once';
    while (! $::DONE[$tid]) {
        pause();
    }
    if ($tid != $detached) {
        $thr->join();
    }
}

exit(0);

# EOF
