use Tibco::Rv;
use Getopt::Long;


my ( %args );
my ( $timeout ) = 5;
die &usage unless ( GetOptions( "service=s" => \$args{service},
   "network=s" => \$args{network}, "daemon=s" => \$args{daemon},
   "timeout=i" => \$timeout ) and @ARGV > 1 );


my ( $subject ) = shift;
my ( $rv ) = new Tibco::Rv( %args );
foreach my $msg ( @ARGV )
{
   my ( $request ) = $rv->createMsg(
      sendSubject => $subject, replySubject => $rv->createInbox, msg => $msg );
   print "Sending request: $request\n";
   my ( $reply ) = $rv->sendRequest( $request, $timeout );
   print ( ( defined $reply ) ? "Received reply: $reply\n" : "No reply!\n" );
}


sub usage
{
   return <<END;
$0 [ -service service ] [ -network network ] [ -daemon daemon ] [ -timeout timeout ] subject message ...
END
}
