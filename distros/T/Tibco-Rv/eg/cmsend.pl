use Tibco::Rv;
use Getopt::Long;


my ( %args );
die &usage unless ( GetOptions( "service=s" => \$args{service},
   "network=s" => \$args{network}, "daemon=s" => \$args{daemon} )
   and @ARGV > 1 );


my ( $subject ) = shift;
my ( $rv ) = new Tibco::Rv( %args );
my ( $cmt ) =
   $rv->createCmTransport( cmName => 'cmsend', ledgerName => 'cmsend.ldg' );
foreach my $msg ( @ARGV )
{
   print "Sending message '$msg'\n";
   $cmt->send( $rv->createCmMsg( sendSubject => $subject, DATA => $msg ) );
}
$rv->start;


sub usage
{
   return <<END;
$0 [ -service service ] [ -network network ] [ -daemon daemon ] subject message ...
END
}
