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
use Test::More 'tests' => 3 + 13 * $nthreads;


### Load module ###

use_ok('Thread::Suspend');


### Setup ###

use lib '.';
require 't/test.pl';

my @threads = make_threads($nthreads);
$_->detach() foreach (@threads);
is(scalar(threads->list()), 0, 'Threads detached');


### Functionality testing ###

foreach my $thr (@threads) {
    my $tid = $thr->tid();

    ok(! threads->is_suspended(), 'No reported suspended threads');
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);

    $thr->suspend();
    is($thr->is_suspended(), 1, "Thread $tid suspended");
    check($thr, 'stopped', __LINE__);

    $thr->suspend();
    ok(! threads->is_suspended(), 'No reported suspended threads');
    is($thr->is_suspended(), 2, "Thread $tid suspended twice");
    check($thr, 'stopped', __LINE__);

    $thr->resume();
    is($thr->is_suspended(), 1, "Thread $tid still suspended");
    check($thr, 'stopped', __LINE__);

    $thr->resume();
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}


### Cleanup ###

foreach my $thr (@threads) {
    my $tid = $thr->tid();
    is($thr->kill('KILL'), $thr, "Thread $tid killed");
    no warnings 'once';
    while (! $::DONE[$tid]) {
        pause();
    }
}

exit(0);

# EOF
