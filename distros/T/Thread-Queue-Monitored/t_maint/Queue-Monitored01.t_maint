BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 3+(2*4);

BEGIN { use_ok('threads') }
BEGIN { use_ok('Thread::Queue::Monitored') }

can_ok( 'Thread::Queue::Monitored',qw(
 dequeue
 dequeue_dontwait
 dequeue_nb
 enqueue
 new
 self
) );

my @list : shared;
my $times = 1000;

check( Thread::Queue::Monitored->new( { monitor => \&monitor } ) );

my ($q,$t) = Thread::Queue->new;
my $exit = 'exit';
($q,$t) = Thread::Queue::Monitored->new(
 {
  monitor => 'monitor',
  queue => $q,
  exit => $exit,
 }
);
check( $q,$t,$exit );

sub check {

  my ($q,$t,$exit) = @_;
  @list = ();

  isa_ok( $q, 'Thread::Queue::Monitored', 'check queue object type' );
  isa_ok( $t, 'threads',		'check thread object type' );

  $q->enqueue( $_ ) foreach 1..$times;
  my $pending = $q->pending;
  ok( ($pending >= 0 and $pending <= $times), 'check number of values on queue' );

  $q->enqueue( $exit ); # stop monitoring
  $t->join;

  my $check = '';
  $check .= $_ foreach 1..$times;
  is( join('',@list), $check,		'check whether monitoring ok' );
} #check

sub monitor { push( @list,$_[0] ) }
