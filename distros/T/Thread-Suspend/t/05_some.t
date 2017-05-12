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
use Test::More 'tests' => 72;


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


my @suspended = threads->suspend($threads[0], $threads[1]->tid());
pause();
is(scalar(@suspended), 2, 'Suspended threads');
foreach my $thr (@suspended) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'Thread suspended');
}

is(scalar(threads->is_suspended()), 2, '2 threads suspended');
foreach my $thr (threads->is_suspended()) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'In suspend list');
}

is(scalar($threads[0]->is_suspended()), 1, 'Thread suspended');
is(scalar($threads[1]->is_suspended()), 1, 'Thread suspended');
is(scalar($threads[2]->is_suspended()), 0, 'Thread not suspended');

@suspended = threads->suspend($threads[2]->tid, $threads[1]);
pause();
is(scalar(@suspended), 2, 'Suspended threads');
foreach my $thr (@suspended) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'Thread suspended');
}

is(scalar(threads->is_suspended()), scalar(@threads), 'All threads suspended');
foreach my $thr (threads->is_suspended()) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'In suspend list');
}

is(scalar($threads[0]->is_suspended()), 1, 'Thread suspended');
is(scalar($threads[1]->is_suspended()), 2, 'Thread suspended twice');
is(scalar($threads[2]->is_suspended()), 1, 'Thread suspended');
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    check($thr, 'stopped', __LINE__);
}

is(scalar(threads->resume($threads[1], $threads[1]->tid())), 2, 'Resume thread twice');
pause();
is(scalar($threads[1]->is_suspended()), 0, 'Thread not suspended');
check($threads[1], 'running', __LINE__);

is(scalar(threads->resume($threads[2], $threads[0]->tid())), 2, 'Resuming threads');
pause();
foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}

# Test with detached threads

my $detached = $threads[2]->tid();
$threads[2]->detach();
ok($threads[2]->is_detached(), 'Thread detached');
is(scalar(threads->list()), scalar(@threads)-1, 'Non-detached threads');

@suspended = threads->suspend($threads[1]->tid(), $threads[2]);
pause();
is(scalar(@suspended), 2, 'Suspended threads');
foreach my $thr (@suspended) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'Thread suspended');
}

is(scalar(threads->is_suspended()), 1, '1 non-detached thread suspended');
foreach my $thr (threads->is_suspended()) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'In suspend list');
}

is(scalar($threads[0]->is_suspended()), 0, 'Thread not suspended');
is(scalar($threads[1]->is_suspended()), 1, 'Thread suspended');
is(scalar($threads[2]->is_suspended()), 1, 'Thread suspended');

@suspended = threads->suspend($threads[2]);
pause();
is(scalar(@suspended), 1, 'Suspended thread');
foreach my $thr (@suspended) {
    is(scalar(grep { $_ == $thr } @threads), 1, 'Thread suspended');
}
is(scalar($threads[2]->is_suspended()), 2, 'Thread suspended twice');

is($threads[0]->suspend, $threads[0], 'Suspended last thread');
pause();

foreach my $thr (@threads) {
    my $tid = $thr->tid();
    check($thr, 'stopped', __LINE__);
}

is(scalar(threads->resume($threads[2], $threads[2])), 2, 'Resume thread twice');
pause();
is(scalar($threads[2]->is_suspended()), 0, 'Thread not suspended');
check($threads[2], 'running', __LINE__);

is(scalar(threads->resume($threads[1], $threads[0]->tid())), 2, 'Resuming threads');
pause();

@suspended = threads->suspend($threads[2]->tid());
pause();
ok(! @suspended, 'Cannot suspend detached thread using TID');

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
