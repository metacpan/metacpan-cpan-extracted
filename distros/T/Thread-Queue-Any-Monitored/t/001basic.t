BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

# modules we need
my %Loaded;
BEGIN {
    $Loaded{threads}= eval "use threads; 1";
    $Loaded{forks}=   eval "use forks; 1" if !$Loaded{threads};
} #BEGIN

use Thread::Queue::Any::Monitored;
use Test::More;

diag "threads loaded" if $Loaded{threads};
diag "forks loaded"   if $Loaded{forks};
ok( $Loaded{threads} || $Loaded{forks}, "thread-like module loaded" );

my $class= 'Thread::Queue::Any::Monitored';
can_ok( $class,qw(
 dequeue
 dequeue_dontwait
 dequeue_keep
 dequeue_nb
 enqueue
 new
 self
) );

# initializations
my @list : shared;
my $times= 1000;

# simple check
check( $class->new( { monitor => \&monitor } ) );

# with given queue and exit value
my ( $q, $t )= Thread::Queue::Any->new;
my $exit= 'exit';
($q,$t) = $class->new( {
  monitor => 'monitor',
  queue   => $q,
  exit    => $exit,
} );
check( $q, $t, $exit );

done_testing( 2 + ( 2 * 3 ) );

#-------------------------------------------------------------------------------
#  IN: 1 queue
#      2 thread
#      3 exit value (undef by default)
#
# Good for 3 tests

sub check {
  my ( $q, $t, $exit )= @_;
  @list= ();

  isa_ok( $q, $class, 'check queue object type' );

  $q->enqueue( [ $_, $_ + 1 ] ) foreach 1..$times;
  my $pending= $q->pending;
  ok( ($pending >= 0 and $pending <= $times),
    'check number of values on queue' );

  $q->enqueue($exit); # stop monitoring
  $t->join;

  my $check= '';
  $check .= ( $_ . ( $_ + 1 ) ) foreach 1..$times;
  is( join( '', @list ), $check, 'check whether monitoring ok' );
} #check

#-------------------------------------------------------------------------------
#  IN: 1 list ref of values to be monitored

sub monitor { push( @list, join( '', @{ $_[0] } ) ) }
#-------------------------------------------------------------------------------
