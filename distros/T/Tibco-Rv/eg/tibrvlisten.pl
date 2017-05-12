use Tibco::Rv;
use Getopt::Long;


my ( %args );
die &usage unless ( GetOptions( "service=s" => \$args{service},
   "network=s" => \$args{network}, "daemon=s" => \$args{daemon} ) and @ARGV );


my ( $rv ) = new Tibco::Rv( %args );
$rv->transport->description( $0 );
map { $rv->createListener( subject => $_, callback => sub {
   my ( $msg ) = shift;
   print Tibco::Rv::Msg::DateTime->now, ": subject=", $msg->sendSubject;
   print ', reply=', $msg->replySubject if ( defined $msg->replySubject );
   print ", message=$msg\n";
} ) } @ARGV;
$rv->start;


sub usage
{
   return <<END;
$0 [ -service service ] [ -network network ] [ -daemon daemon ] subject ...
END
}
