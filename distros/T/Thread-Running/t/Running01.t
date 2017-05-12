BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 19;
use strict;
use warnings;

use_ok( 'Thread::Running' ); # just for the record
can_ok( $_,qw(
 running
 tojoin
 exited
) ) foreach qw(Thread::Running threads);

my $sleep = 2;
my $threads = 5;

my $thread = threads->new( sub { sleep $sleep } );
ok( scalar $thread->running,'thread is running' );

my $tid = $thread->tid;
is( $thread->running,"1", "check running by thread" );
is( scalar threads->running( $tid ),"1", "check running by tid" );

sleep 1 until $thread->exited;
ok( 1,'thread has exited' );

is( $thread->exited,"1", "check exited by thread" );
is( scalar threads->exited( $tid ),"1", "check exited by tid" );

is( $thread->tojoin,"1", "check tojoin by thread" );
is( scalar threads->tojoin( $tid ),"1", "check tojoin by tid" );

$thread->join;

my @thread;
foreach (1..$threads) {
    push @thread,threads->new( sub { sleep $sleep } );
}
my @tid = map { $_->tid } @thread;
sleep 1 until (() = threads->running( @thread )) == @tid;
ok( 1,'all threads are running' );

is( "@{[threads->running( @thread )]}","@tid", "check running by threads" );
is( "@{[threads->running( @tid )]}","@tid", "check running by tids" );

sleep 1 until threads->exited;
ok( 1,'all threads have exited' );

is( "@{[threads->exited( @thread )]}","@tid", "check exited by threads" );
is( "@{[threads->exited( @tid )]}","@tid", "check exited by tids" );

is( "@{[map {$_->tid} threads->tojoin( @thread )]}","@tid", "check tojoin by threads" );
is( "@{[map {$_->tid} threads->tojoin( @tid )]}","@tid", "check tojoin by tids" );

$_->join foreach @thread;
