use Tibco::Rv;
use Getopt::Long;


my ( %args );
die &usage unless ( GetOptions( "service=s" => \$args{service},
   "network=s" => \$args{network}, "daemon=s" => \$args{daemon} )
   and @ARGV > 1 );


my ( $subject ) = shift;
my ( $rv ) = new Tibco::Rv( %args );
foreach my $msg ( @ARGV )
{
   print "Sending message '$msg'\n";
   $rv->send( $rv->createMsg( sendSubject => $subject, DATA => $msg ) );
}


sub usage
{
   return <<END;
$0 [ -service service ] [ -network network ] [ -daemon daemon ] subject message ...
END
}
