use Tibco::Rv;
use Getopt::Long;


my ( %args );
die &usage unless ( GetOptions( "service=s" => \$args{service},
   "network=s" => \$args{network}, "daemon=s" => \$args{daemon} )
   and @ARGV == 1 );


my ( $subject ) = @ARGV;
my ( $rv ) = new Tibco::Rv( %args );
$rv->createCmListener( subject => $subject, cmName => 'cmlisten',
   ledgerName => 'cmlisten.ldg', requestOld => Tibco::Rv::TRUE,
   callback => sub {
   my ( $msg ) = shift;
   print Tibco::Rv::Msg::DateTime->now, ": subject=", $msg->sendSubject,
      ", message=$msg, CMSender: ", $msg->CMSender, ', CMSequence: ',
      $msg->CMSequence, "\n";
} );
$rv->start;


sub usage
{
   return <<END;
$0 [ -service service ] [ -network network ] [ -daemon daemon ] subject
END
}
