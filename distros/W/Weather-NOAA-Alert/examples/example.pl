use Weather::NOAA::Alert;
use Data::Dumper;

my $SLEEP_SECS = 60;   #Poll every 1 minute

#my $alert = Weather::NOAA::Alert->new(['US']);
my $alert = Weather::NOAA::Alert->new(['TXC085', 'TXZ097']);
$alert->printLog(1);
$alert->errorLog(1);

my $events = $alert->get_events();

while (1) {
     my ($errorCount, $eventCount, $addCount, $deleteCount) 
             = $alert->poll_events();
   
     print Dumper( $events) . "\n";
   
     print "Tracking $eventCount " . ($eventCount ==1 ? "event" : "events");
     print "   $addCount added, $deleteCount deleted";
     print ", $errorCount " . ($errorCount ==1 ? "error" : "errors");
     print "\n";
     
     print "Sleeping $SLEEP_SECS seconds\n-----------------\n\n";
     sleep($SLEEP_SECS);
 }
