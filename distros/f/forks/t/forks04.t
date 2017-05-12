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

use Config;
my ($skip_all, $num_tests);
BEGIN {
    $skip_all = 0;
    $num_tests = 97;
    eval {
        require threads; # must be done _before_ Test::More which loads real threads.pm
        require threads::shared;
        unless ($forks::threads_override || $forks::threads_override) {
            $skip_all = 1;
            $num_tests = 1;
        }
    };
    if ($@) {
        $skip_all = 1;
        $num_tests = 1;
        eval {
            *cond_wait = *cond_timedwait = sub {};
        } unless $Config{useithreads};
    }
}

# do the following to prevent unnecessary test script errors
BEGIN {
    if (!defined $threads::VERSION || $threads::VERSION < 1.34) {
        package threads;
        *all = *running = *joinable = sub {};
        package main;
        print <<EOUTPUT;
1..1
ok 1 # skip Forks will not be installed as replacement for threads.pm
EOUTPUT
        exit(0);
    }

    import threads;
    import threads::shared;

    # "Unpatch" Test::More, who internally tries to disable threads
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

# Now load Test::More
BEGIN {
    require Test::More;
    import Test::More tests => $num_tests;
}

use strict;
use warnings;

diag( <<EOD );

These tests exercise general API compatibility and behavior (threads.pm replacement mode).

EOD

SKIP: {
skip 'Forks will not be installed as replacement for threads.pm', $num_tests if $skip_all;

can_ok( 'threads',qw(
 async
 create
 detach
 equal
 import
 isthread
 join
 list
 new
 self
 tid
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
  threads->can('exit') ? threads->exit : exit;
}
sleep 3; # make sure fork above has started to ensure tid's are in sync

my $t1 = threads->new( sub { threads->tid } );
ok( $t1,'check whether we can start a thread with new()' );

my $t2 = threads->create( sub { threads->tid } );
ok( $t2,'check whether we can start a thread with create()' );

my $t3 = async( sub { threads->object( threads->tid )->tid } );
ok( $t3,'check whether we can start a thread with async()' );

my %tid;
$tid{$_->tid} = undef foreach threads->list;
is( join('',sort keys %tid),'234','check tids of all threads' );

is( $t3->join,'4','check return value thread 3' );
is( $t2->join,'3','check return value thread 2' );
is( $t1->join,'2','check return value thread 1' );

#== SCALAR =========================================================

my $scalar = 10;
share( $scalar );
share( $scalar );   #tests that we quietly support re-sharing a shared variable
ok(is_shared( $scalar ), 'check if variable is_shared' );
my $tied = tied( $scalar );
isa_ok( $tied,'threads::shared',    'check tied object type' );

ok( defined $scalar,            'check scalar fetch' );
$scalar = 10;

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
is( join('',@array),'',             'check array fetch' );
push( @array,qw(a b c) );

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

eval{ splice( @array,3,3 ); };
like( $@,qr#^Splice not implemented for shared arrays#,'check splice' );
is( join('',map {$_ || ''} @array),'abcdefghi', 'Check that splice did nothing' );
@array = qw(d e f d e f g h i);

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

#== HASH ===========================================================

my %hash = (a => 'A');
share( %hash );
$tied = tied( %hash );
isa_ok( $tied,'threads::shared',    'check tied object type' );
is( $hash{'a'},undef,       'check hash fetch' );
$hash{'a'} = 'A';

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
ok( $thread->join,"Check if it was the same inside the thread\n" );

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

#90
#== threads->list ==================================================

$thread1 = threads->new( sub { lock $lockvar; cond_wait $lockvar; 1});
$thread2 = threads->new( sub { lock $zoo; cond_wait $zoo; 1});
$thread3 = threads->new( sub { lock $lockvar; cond_wait $lockvar; 1})->detach;
{
    sleep 5;
    lock $lockvar;
    lock $zoo;
    my $num;

    cmp_ok( $num=threads->list(threads::all), '==', 2,"Check for non-joined, non-detached threads" );
    cmp_ok( $num=threads->list(threads::running), '==', 2,"Check for non-detached threads that are still running" );
    cmp_ok( $num=threads->list(threads::joinable), '==', 0,"Check for non-joined, non-detached threads that have finished running" );
    
    cond_broadcast $lockvar;
    cond_signal $zoo;
}
{
    sleep 3;
    my $num;

    cmp_ok( $num=threads->list(threads::all), '==', 2,"Check for non-joined, non-detached threads" );
    cmp_ok( $num=threads->list(threads::running), '==', 0,"Check for non-detached threads that are still running" );
    cmp_ok( $num=threads->list(threads::joinable), '==', 2,"Check for non-joined, non-detached threads that have finished running" );

    $thread1->join();
    cmp_ok( $num=threads->list(threads::all), '==', 1,"Check for non-joined, non-detached threads" );
    cmp_ok( $num=threads->list(threads::joinable), '==', 1,"Check for non-joined, non-detached threads that have finished running" );

    $thread2->join();
}

#98
#===================================================================

} #SKIP

1;
