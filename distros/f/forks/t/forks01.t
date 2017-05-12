#!/usr/local/bin/perl -w
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use forks; # must be done _before_ Test::More which loads real threads.pm
use forks::shared;

diag( <<EOD );

These tests exercise general API compatibility and behavior.

EOD

# "Unpatch" Test::More, who internally tries to disable threads
BEGIN {
    no warnings 'redefine';
    if ($] < 5.008001) {
        require forks::shared::global_filter;
        import forks::shared::global_filter 'Test::Builder';
        require Test::Builder;
        *Test::Builder::share = \&threads::shared::share;
        *Test::Builder::lock = \&threads::shared::lock;
        Test::Builder->new->reset;
    }
}

# Patch Test::Builder to add fork-thread awareness
{
    no warnings 'redefine';
    my $_sanity_check_old = \&Test::Builder::_sanity_check;
    *Test::Builder::_sanity_check = sub {
        my $self = $_[0];
        # Don't bother with an ending if this is a forked copy.  Only the parent
        # should do the ending.
        if( $self->{Original_Pid} != $$ ) {
            return;
        }
        $_sanity_check_old->(@_);
    };
}

use Test::More tests => 151;
use strict;
use warnings;

can_ok( 'threads',qw(
 async
 create
 detach
 equal
 stringify
 import
 isthread
 join
 list
 new
 self
 tid
 is_running
 is_joinable
 is_detached
 is_deadlocked
 _handle
 get_stack_size
 set_stack_size
 wantarray
) );

can_ok( 'threads::shared',qw(
 cond_broadcast
 cond_signal
 cond_wait
 cond_timedwait
 lock
 share
 is_shared
 bless
 TIEARRAY
 TIEHANDLE
 TIEHASH
 TIESCALAR
) );

is( system("echo"),0, 'check that CORE::system still returns correct exit values' );

unless (my $pid = fork) {
  threads->isthread if defined($pid);
  threads->exit;
}
sleep 3; # make sure fork above has started to ensure tid's are in sync

my $test_lock : shared;

my $t1 = threads->new( sub { threads->tid } );
ok( $t1,'check whether we can start a thread with new()' );
cmp_ok( $t1->_handle, '>', 0 ,'check if we can get address of object' );
cmp_ok( threads->_handle, '>', 0 ,'check if we can get address of object' );

my $t2 = threads->create( sub { threads->tid } );
ok( $t2,'check whether we can start a thread with create()' );

my $t3 = async( sub { threads->object( threads->tid )->tid } );
ok( $t3,'check whether we can start a thread with async()' );

my %tid;
$tid{$_->tid} = undef foreach threads->list;
my $thr_cnt = threads->list;
cmp_ok($thr_cnt, '==', 3, 'check that count of threads is correct');
is( join('',sort keys %tid),'234','check tids of all threads' );

ok($t1 == threads->object(2),'check that == works on threads objects');
ok($t1 != threads->object(3),'check that != works on threads objects');

is( $t3->join,'4','check return value thread 3' );
is( $t2->join,'3','check return value thread 2' );
is( $t1->join,'2','check return value thread 1' );

#== error ==========================================================
{
    no warnings 'threads';
    $t1 = threads->new( sub { die 'Thread called die.' } );
    $t2 = threads->new( sub { die bless({status => 'die'}, 'somepkg') } );
}

$t1->join();
like ( $t1->error,qr#^Thread called die. at t/forks01.t#,'check that thread returned expected error' );

$t2->join();
my $err = $t2->error;
is ( ref($err),'somepkg','check that thread returned expected error object' );
is ( eval{$err->{status}},'die','check that thread error object is valid' );

#== exit ===========================================================
$t1 = threads->new( sub { threads->exit() } );
$t1->join();
ok(1, 'check that only one thread exited');

$t1 = threads->new( {'exit' => 'thread_only'}, sub { exit() } );
$t1->join();
ok(1, 'check that only one thread exited');

$t1 = threads->new( sub { threads->set_thread_exit_only(1); exit() } );
$t1->join();
ok(1, 'check that only one thread exited');

$t1 = threads->new( sub { sleep 2; exit() } );
$t1->set_thread_exit_only(1);
$t1->join();
ok(1, 'check that only one thread exited');

$t1 = threads->new( sub { import threads 'exit' => 'threads_only'; exit(); } );
$t1->join();
ok(1, 'check that only one thread exited');

#== SCALAR =========================================================

my $scalar = 10;
share( $scalar );
share( $scalar );   #tests that we quietly support re-sharing a shared variable
ok(is_shared( $scalar ), 'check if variable is_shared' );
my $tied = tied( $scalar );
isa_ok( $tied,'threads::shared',    'check tied object type' );

cmp_ok( $scalar,'==',10,        'check scalar numerical fetch' );
$scalar++;
cmp_ok( $scalar,'==',11,        'check scalar increment' );
$scalar = 'Apenootjes';
is( $scalar,'Apenootjes',       'check scalar fetch' );

threads->new( sub {$scalar = 'from thread'} )->join;
is( $scalar,'from thread',      'check scalar fetch' );

#== ARRAY ==========================================================

my @array = qw(a b c);
share( @array );
$tied = tied( @array );
isa_ok( $tied,'threads::shared',    'check tied object type' );
is( join('',@array),'abc',      'check array fetch' );

push( @array,qw(d e f) );
is( join('',@array),'abcdef',       'check array fetch' );

threads->new( sub {push( @array,qw(g h i) )} )->join;
is( join('',@array),'abcdefghi',    'check array fetch' );

shift( @array );
is( join('',@array),'bcdefghi',     'check array fetch' );

unshift( @array,'a' );
is( join('',@array),'abcdefghi',    'check array fetch' );

pop( @array );
is( join('',@array),'abcdefgh',     'check array fetch' );

push( @array,'i' );
is( join('',@array),'abcdefghi',    'check array fetch' );

splice( @array,3,3 );
is( join('',@array),'abcghi',       'check array fetch' );

splice( @array,3,0,qw(d e f) );
is( join('',@array),'abcdefghi',    'check array fetch' );

splice( @array,0,3,qw(d e f) );
is( join('',@array),'defdefghi',    'check array fetch' );

delete( $array[0] );
is( join('',map {$_ || ''} @array),'efdefghi',      'check array fetch' );

@array = qw(a b c d e f g h i);
is( join('',@array),'abcdefghi',    'check array fetch' );

cmp_ok( $#array,'==',8,         'check size' );
ok( exists( $array[8] ),        'check whether array element exists' );
ok( !exists( $array[9] ),       'check whether array element exists' );

$#array = 10;
cmp_ok( scalar(@array),'==',11,     'check number of elements' );
is( join('',map {$_ || ''} @array),'abcdefghi', 'check array fetch' );

ok( !exists( $array[10] ),      'check whether array element exists' );
$array[10] = undef;
ok( exists( $array[10] ),       'check whether array element exists' );

ok( !exists( $array[11] ),      'check whether array element exists' );
ok( !defined( $array[10] ),     'check whether array element defined' );
ok( !defined( $array[11] ),     'check whether array element defined' );
cmp_ok( scalar(@array),'==',11,     'check number of elements' );

@array = ();
cmp_ok( scalar(@array),'==',0,      'check number of elements' );
is( join('',@array),'',         'check array fetch' );

@array = ();
my $shared_scalar : shared = 'test';
push @array, $shared_scalar;
is($array[0], 'test',           'push with a shared variable works');

#== HASH ===========================================================

my %hash = (a => 'A');
share( %hash );
$tied = tied( %hash );
isa_ok( $tied,'threads::shared',    'check tied object type' );
is( $hash{'a'},'A',         'check hash fetch' );

$hash{'b'} = 'B';
is( $hash{'b'},'B',         'check hash fetch' );

is( join('',sort keys %hash),'ab',  'check hash keys' );

ok( !exists( $hash{'c'} ),      'check existence of key' );
threads->new( sub { $hash{'c'} = 'C' } )->join;
ok( exists( $hash{'c'} ),       'check existence of key' );
is( $hash{'c'},'C',         'check hash fetch' );

is( join('',sort keys %hash),'abc', 'check hash keys' );

my %otherhash = %hash;
is( join('',sort keys %otherhash),'abc','check hash keys' );

my @list;
while (my ($key,$value) = each %hash) { push( @list,$key,$value ) }
is( join('',sort @list),'ABCabc',   'check all eaches' );

delete( $hash{'b'} );
is( join('',sort keys %hash),'ac',  'check hash keys' );

%hash = ();
cmp_ok( scalar(keys %hash),'==',0,  'check number of elements' );
is( join('',keys %hash),'',     'check hash fetch' );

#== errors =========================================================

my $foo;
eval {lock $foo};
like( $@,qr#^lock can only be used on shared values#,'check unshared var' );

my $bar : shared;
eval {cond_wait $bar};
like( $@,qr#^You need a lock before you can cond_wait#,'check unlocked var' );

eval {cond_timedwait $bar, time() + 5};
like( $@,qr#^You need a lock before you can cond_timedwait#,'check unlocked var' );

eval {lock $bar};
is( $@,'','check locking shared var' );

eval {lock $bar; cond_signal $bar};
is( $@,'','check locking and signalling shared var' );

my %foo : shared;
eval {$foo{1}{foo}='a'};
like( $@,qr#^Invalid value for shared scalar#,'check store disallowed for non-shared ref' );

#== detach and join errors =========================================

{
    my ($t1, $t2);
    
    $t1 = threads->new(sub {});
    $t1->detach();
    eval { $t1->detach(); };
    like( $@,qr#^Thread already detached#,'check die on detach detached' );

    $t1 = threads->new(sub { sleep 3; });
    $t2 = threads->new(sub { $t1->detach(); });
    sleep 2;
    eval { $t1->join(); };
    like( $@,qr#^Cannot join a detached thread#,'check die on join detached' );
    $t2->join;
    
    $t1 = threads->new(sub { sleep 3; });
    $t2 = threads->new(sub { $t1->join(); });
    sleep 2;
    eval { $t1->join(); };
    like( $@,qr#^Thread already joined#,'check die on join joined' );
    $t2->join;
    
# TODO: Unable to trigger this case yet (forks-specific cases, only in very specific circumstances)
#    $t1 = threads->new(sub {});
#    $t2 = threads->new(sub { $t1->join(); });
#    sleep 2;
#    eval { $t1->join(); };
#    like( $@,qr#^Cannot join a detached or already joined thread#,'check die on join joined' );
#    $t2->join;
}

#== fixed bugs =====================================================

my $zoo : shared;
my $thread = threads->new( sub { sleep 2; lock $zoo; cond_signal $zoo; 1} );
{
    lock $zoo;
    cond_wait $zoo;
    ok( 1, "We've come back from the thread!" );
}
ok( $thread->join,"Check if came back correctly from thread" );

{
    lock $zoo;
    my $data = 'x' x 100000;
    $thread = threads->new( sub {
        lock $zoo;
        return $zoo eq $data;
    } );
    $zoo = $data;
}
ok( $thread->join,"Check if it was the same inside the thread" );

#$thread = threads->new( sub { sleep 2; cond_signal $zoo} );
#lock $zoo;
#cond_wait $zoo;
#ok( 1, "We've come back from the thread!" );
#$thread->join;

#== cond_timedwait =================================================
$zoo = threads->tid;
$thread = threads->new( sub { sleep 2; { lock $zoo; cond_signal $zoo; } sleep 10; lock $zoo; cond_signal $zoo; $zoo = threads->tid; 1} );
{
    lock $zoo;
    cond_wait $zoo;
    my $start_ts = time();
    my $ret = cond_timedwait $zoo, time() + 2;
    cmp_ok( $zoo, '==', threads->tid, "check that cond_timedwait exited due to timeout (before signal)" );
    cmp_ok( !$ret, '==', 1, "check that cond_timedwait exited with correct value" );

    $ret = cond_timedwait $zoo, time() + 30;
    cmp_ok( $zoo, '==', $thread->tid, "check that cond_timedwait signal was handled correctly" );
    cmp_ok( time() - $start_ts, '<', 30, "check that cond_timedwait exited due to signal and not after it expired" );
    cmp_ok( $ret, '==', 1, "check that cond_timedwait exited with correct value" );
    sleep 1;
}
ok( $thread->join,"Check if came back correctly from thread" );

$zoo = threads->tid;
my ($thread1, $thread2, $thread3);
$thread1 = threads->new( sub { lock $zoo; cond_timedwait $zoo, time() + 40; $zoo = threads->tid; 1} );
$thread2 = threads->new( sub { lock $zoo; cond_timedwait $zoo, time() + 1; $zoo = threads->tid; 1} );
$thread3 = threads->new( sub { lock $zoo; cond_timedwait $zoo, time() + 30; $zoo = threads->tid; 1} );
{
    my $start_ts = time();
    sleep 5;
    cmp_ok( $zoo, '==', $thread2->tid, "check that thread2 cond_timedwait exited due to timeout" );
    { lock $zoo; cond_signal $zoo; }
    { lock $zoo; cond_signal $zoo; }
    ok( $thread1->join,"Check if came back correctly from thread1" );
    ok( $thread2->join,"Check if came back correctly from thread2" );
    ok( $thread3->join,"Check if came back correctly from thread3" );
    cmp_ok( time() - $start_ts, '<', 30, "check that thread1 & thread3 exited due to cond_signal and not after cond_timedwait expired" );
}

$thread1 = threads->new( sub { lock $zoo; cond_timedwait $zoo, time() + 40; 1} );
$thread2 = threads->new( sub { lock $zoo; cond_timedwait $zoo, time() + 30; 1} );
$thread3 = threads->new( sub { lock $zoo; cond_wait $zoo; 1} );
{
    my $start_ts = time();
    sleep 5;
    { lock $zoo; cond_broadcast $zoo; }
    ok( $thread1->join,"Check if came back correctly from thread1" );
    ok( $thread2->join,"Check if came back correctly from thread2" );
    ok( $thread3->join,"Check if came back correctly from thread3" );
    cmp_ok( time() - $start_ts, '<', 30, "check that thread1, thread2, and thread3 exited due to cond_broadcast" );
}

#== cond_wait, cond_timedwait second forms =========================

my $lockvar : shared;
$zoo = threads->tid;
$thread = threads->new( sub { sleep 2; { lock $zoo; cond_signal $zoo; } sleep 2; lock $zoo; cond_signal $zoo; lock $lockvar; sleep 5; $zoo = threads->tid; 1} );
{
    { lock $zoo; cond_wait $zoo; }
    lock $lockvar;
    cond_wait $zoo, $lockvar;
    sleep 1;
    cmp_ok( $zoo, '==', threads->tid, "check that main thread received signal before thread could lock it" );
}
ok( $thread->join,"Check if came back correctly from thread" );

$zoo = threads->tid;
$thread = threads->new( sub { sleep 2; { lock $zoo; cond_signal $zoo; } sleep 5; lock $zoo; cond_signal $zoo; lock $zoo; $zoo = threads->tid; 1} );
{
    { lock $zoo; cond_wait $zoo; }
    my $start_ts = time();
    lock $lockvar;
    my $ret = cond_timedwait $zoo, time() + 2, $lockvar;
    cmp_ok( $zoo, '==', threads->tid, "check that cond_timedwait exited due to timeout (before signal)" );
    cmp_ok( !$ret, '==', 1, "check that cond_timedwait exited with correct value" );    

    $ret = cond_timedwait $zoo, time() + 30, $lockvar;
    sleep 2;
    lock $zoo;
    cmp_ok( $zoo, '==', $thread->tid, "check that cond_timedwait signal was handled correctly" );
    cmp_ok( time() - $start_ts, '<', 30, "check that cond_timedwait exited due to signal and not after it expired" );
    cmp_ok( $ret, '==', 1, "check that cond_timedwait exited with correct value" );
    sleep 1;
}
ok( $thread->join,"Check if came back correctly from thread" );

$thread1 = threads->new( sub { lock $lockvar; cond_timedwait $zoo, time() + 40, $lockvar; 1} );
$thread2 = threads->new( sub { lock $lockvar; cond_timedwait $zoo, time() + 30, $lockvar; 1} );
$thread3 = threads->new( sub { lock $lockvar; cond_wait $zoo, $lockvar; 1} );
{
    my $start_ts = time();
    sleep 5;
    { lock $lockvar; lock $zoo; cond_broadcast $zoo; }
    ok( $thread1->join,"Check if came back correctly from thread1" );
    ok( $thread2->join,"Check if came back correctly from thread2" );
    ok( $thread3->join,"Check if came back correctly from thread3" );
    cmp_ok( time() - $start_ts, '<', 30, "check that thread1, thread2, and thread3 exited due to cond_broadcast" );
}

#== threads->list, is_running, is_joinable, isdetached =============
$thread1 = threads->new( sub { lock $lockvar; cond_wait $lockvar; 1});
$thread2 = threads->new( sub {
    {
        lock $test_lock;
        ok( !threads->is_detached(),"Check that thread->is_detached returns false");
    }
    lock $zoo;
    cond_wait $zoo;
    1
});
$thread3 = threads->new( sub {
    lock $lockvar;
    cond_wait $lockvar;
    {
        lock $test_lock;
        ok( threads->is_detached(),"Check that thread->is_detached returns true");
    }
    1
});
$thread3->detach;
{
    sleep 5;
    lock $lockvar;
    lock $zoo;
    my $num;
    
    {
        lock $test_lock;
        ok( $thread1->is_running(),"Check that thread is_running returns true" );
        ok( !$thread1->is_joinable(),"Check that thread is_joinable returns false" );    
        ok( !$thread1->is_detached(),"Check that thread is_detached returns false" );    
        ok( $thread3->is_running(),"Check that thread is_running returns true" );
        ok( !$thread3->is_joinable(),"Check that thread is_joinable returns false" );    
        ok( $thread3->is_detached(),"Check that thread is_detached returns true" );    

        cmp_ok( $num=threads->list(threads::all), '==', 2,"Check for non-joined, non-detached threads" );
        cmp_ok( $num=threads->list(threads::running), '==', 2,"Check for non-detached threads that are still running" );
        cmp_ok( $num=threads->list(threads::joinable), '==', 0,"Check for non-joined, non-detached threads that have finished running" );
    }
    
    cond_broadcast $lockvar;
    cond_signal $zoo;
}
{
    sleep 3;
    my $num;

    {
        lock $test_lock;
        cmp_ok( $num=threads->list(threads::all), '==', 2,"Check for non-joined, non-detached threads" );
        cmp_ok( $num=threads->list(threads::running), '==', 0,"Check for non-detached threads that are still running" );
        cmp_ok( $num=threads->list(threads::joinable), '==', 2,"Check for non-joined, non-detached threads that have finished running" );

        ok( $thread1->is_joinable(),"Check that thread is_joinable returns true" );
    }

    $thread1->join();

    {
        lock $test_lock;
        ok( !$thread1->is_running(),"Check that thread is_running returns false" );
        ok( !$thread1->is_joinable(),"Check that thread is_joinable returns false" );    

        cmp_ok( $num=threads->list(threads::all), '==', 1,"Check for non-joined, non-detached threads" );
        cmp_ok( $num=threads->list(threads::joinable), '==', 1,"Check for non-joined, non-detached threads that have finished running" );
    }

    $thread2->join();
}

#== thread stack size ==============================================
cmp_ok( threads->get_stack_size(), '==', 0, "Check for default thread stack size" );
{
    threads->set_stack_size( 64*4096 );
    cmp_ok( threads->get_stack_size(), '>', 0, "Check for custom thread stack size" );
    $thread1 = threads->new( sub { 1 });
    cmp_ok( $thread1->get_stack_size(), '>', 0, "Check for custom thread stack size" );
    $thread1->join();

    threads->set_stack_size( 0 );
    cmp_ok( threads->get_stack_size(), '==', 0, "Check for default thread stack size" );
    $thread1 = threads->new({ 'stack' => 4096*64 }, sub { 1 });
    cmp_ok( $thread1->get_stack_size(), '>', 0, "Check for custom thread stack size" );

    $thread2 = $thread1->create( sub { 1 } );
    cmp_ok( $thread2->get_stack_size(), '==', 4096*64, "Check for default stack size" );
    $thread1->join();
    $thread2->join();
}

#== thread context =================================================

{
    my $scalar;
    @list = ();
    
    ($thread1) = threads->create( sub {
        {
            lock $test_lock;
            ok( threads->wantarray(),"Check thread implicit context is list" );
        }
        return qw(a b c);
    } );
    sleep 2;    #Test::More race-condition protection
    {
        lock $test_lock;
        ok( $thread1->wantarray(), "Check thread implicit context is list" );
    }
    @list = $thread1->join();
    is( join('',@list), 'abc', 'check list return result' );
    
    $thread1 = threads->create( sub {
        {
            lock $test_lock;
            cmp_ok( threads->wantarray(), '==', 0, "Check thread implicit context is scalar" );
        }
        return 'abc';
    } );
    sleep 2;    #Test::More race-condition protection
    {
        lock $test_lock;
        cmp_ok( $thread1->wantarray(), 'eq', '', "Check thread implicit context is scalar" );
    }
    $scalar = $thread1->join();
    {
        lock $test_lock;
        is( $scalar, 'abc', 'check scalar return result' );
    }
    
    threads->create( sub {
        {
            lock $test_lock;
            ok( !defined threads->wantarray(), "Check thread implicit context is void" );
        }
        return;
    } );
    $_->join() foreach threads->list();

    $thread1 = threads->create( { 'context' => 'list' }, sub {
        {
            lock $test_lock;
            ok( threads->wantarray(),"Check thread context is list" );
        }
        return 'def';
    } );
    sleep 2;    #Test::More race-condition protection
    {
        lock $test_lock;
        ok( $thread1->wantarray(), "Check thread context is list" );
    }
    @list = $thread1->join();
    {
        lock $test_lock;
        is( join('',@list), 'def', 'check array return result' );
    }
    
    $thread1 = threads->create( { 'context' => 'scalar' }, sub {
        {
            lock $test_lock;
            cmp_ok( threads->wantarray(), '==', 0, "Check thread context is scalar" );
        }
        return qw(a b c); 
    } );
    sleep 2;    #Test::More race-condition protection
    {
        lock $test_lock;
        cmp_ok( $thread1->wantarray(), 'eq', '', "Check thread context is scalar" );
    }
    $scalar = $thread1->join();
    {
        lock $test_lock;
        is( $scalar, 'c', 'check scalar return result' );
    }
    
    $thread1 = threads->create( { 'context' => 'void' }, sub {
        {
            lock $test_lock;
            ok( !defined threads->wantarray(), "Check thread context is void" );
        }
        return 'abc'; 
    } );
    sleep 2;    #Test::More race-condition protection
    {
        lock $test_lock;
        ok( !defined $thread1->wantarray(),"Check thread context is void" );
    }
    $scalar = $thread1->join();
    {
        lock $test_lock;
        ok( !defined $scalar, 'check void return result' );
    }
}

#== stringify ======================================================

isnt( "$thread1", $thread1->tid, "Check that stringify is not enabled" );
import forks qw(stringify);
$thread1 = threads->new( sub { 1 });
$thread1->join();
is( "$thread1", $thread1->tid, "Check that stringify works" );

#===================================================================

1;
