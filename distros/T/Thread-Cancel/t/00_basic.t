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

use Test::More 'tests' => 28;

use_ok('Thread::Cancel');

if ($Thread::Cancel::VERSION) {
    diag('Testing Thread::Cancel ' . $Thread::Cancel::VERSION);
}

can_ok('threads', qw(cancel));

sub test_loop
{
    my $x = 1;
    while ($x > 0) { threads->yield(); }
}

my $thr = threads->create('test_loop');
ok($thr, 'Thread created');
ok($thr->is_running(), 'Thread running');
ok(! $thr->is_detached(), 'Thread not detached');
ok(! $thr->cancel(), 'Thread cancelled');
threads->yield();
sleep(1);
ok(! $thr->is_running(), 'Thread not running');
ok($thr->is_detached(), 'Thread detached');

$thr = threads->create(sub { threads->self()->cancel(); });
threads->yield();
sleep(1);
ok(! $thr->is_running(), 'Thread not running');
ok($thr->is_detached(), 'Thread detached');

$thr = threads->create('test_loop');
my $thr2 = threads->create('test_loop');
ok($thr && $thr2, 'Thread created');
$thr->detach();
ok(! threads->cancel(), 'Threads cancelled');
threads->yield();
sleep(1);
ok(! $thr2->is_running(), 'Thread not running');
ok($thr2->is_detached(), 'Thread detached');
ok($thr->is_running(), 'Thread still running');
ok($thr->is_detached(), 'Thread detached');
ok(! $thr->cancel(), 'Thread cancelled');
threads->yield();
sleep(1);
ok(! $thr->is_running(), 'Thread not running');

$thr = threads->create('test_loop');
$thr2 = threads->create('test_loop');
ok($thr && $thr2, 'Thread created');
$thr2->detach();
ok(! threads->cancel($thr2, $thr->tid()), 'Threads cancelled');
threads->yield();
sleep(1);
ok(! $thr->is_running(), 'Thread not running');
ok($thr->is_detached(), 'Thread detached');
ok(! $thr2->is_running(), 'Thread not running');
ok($thr2->is_detached(), 'Thread detached');

SKIP:
{
    eval 'use Thread::Suspend';
    skip('Thread::Suspend not available', 4) unless threads->can('suspend');

    $thr = threads->create(sub { threads->self()->suspend(); });
    threads->yield();
    sleep(1);
    ok($thr->is_suspended(), 'Thread suspended');
    ok(! $thr->cancel(), 'Thread cancelled');
    threads->yield();
    sleep(1);
    ok(! $thr->is_running(), 'Thread not running');
    ok($thr->is_detached(), 'Thread detached');
}

exit(0);

# EOF
