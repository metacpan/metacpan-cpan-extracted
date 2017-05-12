BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 3 + (2 * (4 * (2 * 4)));

BEGIN { use_ok('threads') }
BEGIN { use_ok('Thread::Conveyor::Monitored') }

can_ok( 'Thread::Conveyor::Monitored',qw(
 belt
 clean
 clean_dontwait
 new
 onbelt
 peek
 peek_dontwait
 put
 shutdown
 take
 take_dontwait
 thread
 tid
) );

my @list : shared;

diag ( "Monitoring to array" );

foreach my $optimize (qw(cpu memory)) {

foreach my $times (10,100,1000,int(rand(1000))) {

diag ( "$times boxes optimized for $optimize" );

  check( Thread::Conveyor::Monitored->new(
   {
    optimize => $optimize,
    monitor => \&monitor,
   }
  ),$times );

  my $belt = Thread::Conveyor->new( {optimize => $optimize} );
  my $exit = 'exit';
  my $mbelt = Thread::Conveyor::Monitored->new(
   {
    monitor => 'monitor',
    belt => $belt,
    exit => $exit,
   }
  );
  check( $mbelt,$times,$exit,1 );
} #$times

} #$optimize

sub check {

  my ($mbelt,$times,$exit,$shutdown) = @_;
  my $mthread = $mbelt->thread;
  @list = ();

  isa_ok( $mbelt, 'Thread::Conveyor::Monitored', 'check belt object type' );
  isa_ok( $mthread, 'threads',		'check thread object type' );

  my $belt = $mbelt->belt;
  $mbelt->put( [$_,$_+1] ) foreach 1..$times;
  my $onbelt = $mbelt->onbelt;
  ok( ($onbelt >= 0 and $onbelt <= $times), 'check number of values on belt' );

  $mbelt->shutdown;

  my $check = '';
  $check .= ($_.($_+1)) foreach 1..$times;
  is( join('',@list), $check,		'check whether monitoring ok' );
} #check

sub monitor { push( @list,join('',@{$_[0]}) ) }
