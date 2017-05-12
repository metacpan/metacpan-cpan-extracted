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
use Test::More 'tests' => 3 + 18 * $nthreads;


### Load module ###

use_ok('Thread::Suspend');

if ($Thread::Suspend::VERSION) {
    diag('Testing Thread::Suspend ' . $Thread::Suspend::VERSION);
}

can_ok('threads', qw(suspend is_suspended resume));


### Setup ###

use lib '.';
require 't/test.pl';

my @threads = make_threads($nthreads);


### Functionality testing ###

foreach my $thr (@threads) {
    my $tid = $thr->tid();

    ok(! threads->is_suspended(), 'No threads suspended');
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);

    $thr->suspend();
    is(scalar(threads->is_suspended()), 1, 'One thread suspended');
    ok((threads->is_suspended())[0] == $thr, "Thread $tid suspended");
    is($thr->is_suspended(), 1, "Thread $tid suspended");
    check($thr, 'stopped', __LINE__);

    $thr->suspend();
    is(scalar(threads->is_suspended()), 1, 'One thread suspended');
    ok((threads->is_suspended())[0] == $thr, "Thread $tid suspended");
    is($thr->is_suspended(), 2, "Thread $tid suspended twice");
    check($thr, 'stopped', __LINE__);

    $thr->resume();
    is(scalar(threads->is_suspended()), 1, 'One thread suspended');
    ok((threads->is_suspended())[0] == $thr, "Thread $tid suspended");
    is($thr->is_suspended(), 1, "Thread $tid still suspended");
    check($thr, 'stopped', __LINE__);

    $thr->resume();
    ok(! threads->is_suspended(), 'No threads suspended');
    is($thr->is_suspended(), 0, "Thread $tid not suspended");
    check($thr, 'running', __LINE__);
}


### Cleanup ###

$_->kill('KILL')->join() foreach (@threads);

exit(0);

# EOF
