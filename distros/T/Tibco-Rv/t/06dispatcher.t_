$^W = 0;

use Tibco::Rv;

print "1..7\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
( defined $rv ) ? &ok : &nok;
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },
   transport => $rv->transport );

my ( $transport ) = $rv->createTransport( description => 'myTransport' );
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },
   transport => $transport );
( $transport->description eq 'myTransport' ) ? &ok : &nok;
eval
{
   ( $transport->batchMode( Tibco::Rv::Transport::TIMER_BATCH ) &&
      $transport->batchMode == Tibco::Rv::Transport::TIMER_BATCH ) ? &ok : &nok;
};
if ( $@ )
{
   ( $Tibco::Rv::TIBRV_VERSION_RELEASE < 7 &&
      $@ == Tibco::Rv::VERSION_MISMATCH ) ? &ok : &nok;
}

my ( $dispatcher );

my ( $request_reply_ok ) = 0;
my ( $queue ) = new Tibco::Rv::Queue( name => 'myQueue' );
my ( $listener ) = new Tibco::Rv::Listener( subject => 'MY.TEST',
   queue => $queue, transport => $transport, callback => sub {
   my ( $msg ) = @_;
   my ( $reply ) = $rv->createMsg( dispatcherName => $dispatcher->name );
   $transport->sendReply( $reply, $msg );
} );

$dispatcher = new Tibco::Rv::Dispatcher( dispatchable => $queue,
   idleTimeout => 20 );
$dispatcher->name( 'myDispatcher' );

my ( $t );
$t = $rv->createTimer( interval => .1, callback => sub
{
   my ( $inbox ) = $rv->transport->createInbox;
   my ( $request ) = $rv->createMsg( replySubject => $inbox,
      sendSubject => 'MY.TEST' );
   my ( $reply ) = $rv->transport->sendRequest( $request );
   ( $reply->getString( 'dispatcherName' ) eq 'myDispatcher' ) ? &ok : &nok;
   ( $dispatcher->idleTimeout == 20 ) ? &ok : &nok;
   ( $dispatcher->dispatchable->name eq 'myQueue' ) ? &ok : &nok;
   $t->DESTROY;
   $rv->stop;
   $request_reply_ok = 1;
} );
$rv->start;

( $request_reply_ok ) ? &ok : &nok;
