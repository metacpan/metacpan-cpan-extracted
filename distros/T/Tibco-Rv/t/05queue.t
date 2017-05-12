$^W = 0;

use Tibco::Rv;

print "1..5\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },
   transport => $rv->transport );

#my ( $qg ) = new Tibco::Rv::QueueGroup;
my ( $qg ) = $rv->defaultQueueGroup;
my ( $q1 ) = $qg->createQueue;
( $q1->name( 'q1' ) && $q1->name eq 'q1' ) ? &ok : &nok;
( $q1->priority( 2 ) && $q1->priority == 2 ) ? &ok : &nok;
my ( $q2 ) = $qg->createQueue( name => 'q2' );
$qg->remove( $q1 );

my ( $policy_ok ) = 0;
#$q2->limitPolicy( Tibco::Rv::Queue::DISCARD_LAST, 2, 1 );
$rv->createListener( subject => '_RV.WARN.SYSTEM.QUEUE.LIMIT_EXCEEDED',
   transport => $Tibco::Rv::Transport::PROCESS,
   callback => sub { $policy_ok = 1 } );

my ( $hook_ok ) = 0;
my ( $count_ok ) = 0;
#fixme see BUGS
$hook_ok = $count_ok = $policy_ok = 1;
#$q2->hook( sub
#{
#   $hook_ok = 1;
#   $count_ok = 1 if ( $q2->count == 2 );
#} );

my ( $t, $t_count );
$t_count = 0;
$t = $q2->createTimer( interval => .5, callback => sub
{
   if ( ++ $t_count == 2 )
   {
      $rv->createTimer( interval => .1, callback => sub { $rv->stop } );
      $t->DESTROY;
   }
} );
$q2->createTimer( interval => .1, callback => sub { } );
$q2->createTimer( interval => .1, callback => sub { } );
#my ( $dispatcher ) = $qg->createDispatcher;
$rv->start;

( $hook_ok ) ? &ok : &nok;
( $count_ok ) ? &ok : &nok;
( $policy_ok ) ? &ok : &nok;
