BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 18;
use strict;
use warnings;

use_ok( 'Thread::Running', qw(exited running tojoin) );
can_ok( 'main',qw(
 running
 tojoin
 exited
) );

my $sleep = 2;
my $threads = 5;

my $thread = threads->create( sub { sleep $sleep } );
my $tid = $thread->tid;
sleep 1 until $thread->running;
ok( 1,'thread is running' );

is( scalar running( $thread ),"1", "check running by thread" );
is( scalar running( $tid ),"1", "check running by tid" );

sleep 1 until $thread->tojoin;
ok( 1,'thread can be joined' );

is( scalar exited( $thread ),"1", "check exited by thread" );
is( scalar exited( $tid ),"1", "check exited by tid" );

is( scalar tojoin( $thread ),"1", "check tojoin by thread" );
is( scalar tojoin( $tid ),"1", "check tojoin by tid" );

$thread->join;

my @thread;
foreach (1..$threads) {
    push @thread,threads->create( sub { sleep $sleep } );
}
my @tid = map { $_->tid } @thread;
sleep 1 until (() = threads->running( @thread )) == @tid;
ok( 1,'all threads are running' );

is( "@{[running( @thread )]}","@tid", "check running by threads" );
is( "@{[running( @tid )]}","@tid", "check running by tids" );

sleep 1 until (() = threads->tojoin( @thread )) == @tid;
ok( 1,'all threads can be joined' );

is( "@{[exited( @thread )]}","@tid", "check exited by threads" );
is( "@{[exited( @tid )]}","@tid", "check exited by tids" );

is( "@{[map {$_->tid} tojoin( @thread )]}","@tid", "check tojoin by threads" );
is( "@{[map {$_->tid} tojoin( @tid )]}","@tid", "check tojoin by tids" );

$_->join foreach @thread;
