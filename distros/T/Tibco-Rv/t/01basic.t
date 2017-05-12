$^W = 0;

use Tibco::Rv;

print "1..3\n";
my ( $ok ) = 0;
sub ok { print 'ok ' . ++ $ok . "\n" }
sub nok { print 'not ok ' . ++ $ok . "\n" }


my ( $rv ) = new Tibco::Rv;
$rv->createListener( subject => '_RV.WARN.>', callback => sub { },
   transport => $rv->transport );
( defined $rv ) ? &ok : &nok;

my ( $status ) = new Tibco::Rv::Status( status => Tibco::Rv::NO_MEMORY );
( $status->toString eq 'Memory allocation failed' ) ? &ok : &nok;
( $status->toNum == 19 ) ? &ok : &nok;
