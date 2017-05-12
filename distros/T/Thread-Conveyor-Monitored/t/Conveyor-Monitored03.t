BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 4 + (2 * (6 * (2 * 4) + 1));

BEGIN { use_ok('threads') }
BEGIN { use_ok('Thread::Conveyor::Monitored') }

cmp_ok( Thread::Conveyor::Monitored->frequency,'==',1000,
 'check default frequency' );
cmp_ok( Thread::Conveyor::Monitored->frequency( 100 ),'==',100,
 'check setting of default frequency' );

my @list : shared;
my $checkpointed : shared;

diag ( "Monitoring with checkpoints" );

foreach my $optimize (qw(cpu memory)) {
  $checkpointed = 0;

foreach my $times (10,11,9,100,101,99) {

diag ( "$times boxes optimized for $optimize" );

  check( Thread::Conveyor::Monitored->new(
   {
    optimize   => $optimize,
    monitor    => \&monitor,
    checkpoint => \&checkpoint,
    frequency  => 10,
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

  cmp_ok( $checkpointed,'==',31,	'check number of checkpoints' );

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

sub checkpoint { $checkpointed++ }
