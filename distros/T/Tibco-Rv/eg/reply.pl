package Replyer;
use base qw/ Tibco::Rv::Listener /;


sub onEvent
{
   my ( $self, $request ) = @_;
   print "Received request: $request\n";
   my ( $reply ) = new Tibco::Rv::Msg( msg => "$request" );
   $reply->addDateTime( at => new Tibco::Rv::Msg::DateTime->now );
   print "Sending reply: $reply\n";
   $self->transport->sendReply( $reply, $request );
}


package main;


use Tibco::Rv;
use Getopt::Long;


my ( %args );
die &usage unless ( GetOptions( "service=s" => \$args{service},
   "network=s" => \$args{network}, "daemon=s" => \$args{daemon} ) and @ARGV );


my ( $rv ) = new Tibco::Rv( %args );
map { new Replyer( subject => $_, transport => $rv->transport ) } @ARGV;
$rv->start;


sub usage
{
   return <<END;
$0 [ -service service ] [ -network network ] [ -daemon daemon ] subject ...
END
}
