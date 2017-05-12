$^W = 0;

use Tibco::Rv;

print "1..3\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },                 transport => $rv->transport );
pipe( *IN, *OUT );

my ( $io, $timer, $listener );
my ( $io_ok, $timer_ok, $listener_ok ) = ( 0, 0, 0 );
$io = $rv->createIO( socketId => fileno( IN ),
   ioType => Tibco::Rv::IO::READ, callback => sub {
   my ( $x );
   $x = <IN>;
   $io_ok = 1  if ( $x eq "abc\n" );
   $io->DESTROY;
} );
$timer = $rv->createTimer( interval => 1, callback => sub {
   $timer_ok = 1;
   my ( $msg ) = $rv->createMsg;
   $msg->sendSubject( 'PERL.TIBCO.RV.TEST' );
   $rv->send( $msg );
   $timer->DESTROY;
} );
$listener =
   $rv->createListener( subject => 'PERL.TIBCO.RV.TEST', callback => sub
{
   $listener_ok = 1;
   print OUT "abc\n";
   close( OUT );
} );
$rv->createTimer( interval => 3, callback => sub { $rv->stop } );


$rv->start;
( $io_ok ) ? &ok : &nok;
( $timer_ok ) ? &ok : &nok;
( $listener_ok ) ? &ok : &nok;
