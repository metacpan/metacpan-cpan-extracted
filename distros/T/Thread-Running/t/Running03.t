BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 17;
use strict;
use warnings;

use Thread::Running;
can_ok( 'main',qw(
 running
 tojoin
 exited
) );

my $sleep = 2;
my $threads = 5;

my $thread = threads->new( sub { sleep $sleep } );
my $tid = $thread->tid;
sleep 1 until $thread->running;
ok( 1,'thread is running' );

is( scalar running( $thread ),"1", "check running by thread" );
is( scalar running( $tid ),"1", "check running by tid" );

$thread->detach;
sleep 1 while $thread->running;
ok( 1,'thread has exited' );

is( scalar exited( $thread ),"1", "check exited by thread" );
is( scalar exited( $tid ),"1", "check exited by tid" );

cmp_ok( scalar tojoin( $thread ),'==',0, "check tojoin by thread" );
cmp_ok( scalar tojoin( $tid ),'==',0, "check tojoin by tid" );

my @thread;
foreach (1..$threads) {
    push @thread,threads->new( sub { sleep $sleep } );
}
my @tid = map { $_->tid } @thread;
sleep 1 until (() = threads->running( @thread )) == @tid;
ok( 1,'all threads are running' );

is( "@{[running( @thread )]}","@tid", "check running by threads" );
is( "@{[running( @tid )]}","@tid", "check running by tids" );

$_->detach foreach @thread;
sleep 1 until (() = threads->running( @thread )) == 0;
ok( 1,'all threads have exited' );

is( "@{[exited( @thread )]}","@tid", "check exited by threads" );
is( "@{[exited( @tid )]}","@tid", "check exited by tids" );

cmp_ok( scalar tojoin( @thread ),'==',0, "check tojoin by threads" );
cmp_ok( scalar tojoin( @tid ),'==',0, "check tojoin by tids" );
