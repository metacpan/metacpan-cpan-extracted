use Test::More 'no_plan';
use Data::Dumper;
use Log::Log4perl qw( :levels);

Log::Log4perl->easy_init($DEBUG);

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok('perfSONAR_PS::Services::MP::Config::PingER');

# instantiate
my $schedule = perfSONAR_PS::Services::MP::Config::PingER->new();
ok( $schedule->isa( 'perfSONAR_PS::Services::MP::Config::PingER'), 'Instantiation');

# load the example file
my $file = 't/testfiles/pinger-landmarks.xml';
ok( $schedule->load( $file ) eq 0, "loading file '$file'");

# get list of testids
my @testids = $schedule->getAllTestIds();
# print Data::Dumper::Dumper(@testids);
ok( scalar @testids eq 4, "All tests ids found");

# check for first test; would return undef as no period is defined
$id = 'urn:ogf:network:domain=mcgill.ca:node=hep.physics:packetSize=100:count=10:interval=1:ttl=64';
ok( ! $schedule->getTestNextTimeFromNowById( $id ), "No defined period" );

# test 2 should have just have the period; as no offset is defined
$id = 'urn:ogf:network:domain=cern.ch:node=www:packetSize=1000:count=10:interval=1:ttl=255';
ok( $schedule->getTestNextTimeFromNowById( $id ) eq 30, "No defined offset" );


# test 3 should return a value between 270 and 330 (300 +/- 30)
$id = 'urn:ogf:network:domain=pacific.net.sg:node=noc:packetSize=1000:count=10:interval=1:ttl=43';
my $time = $schedule->getTestNextTimeFromNowById( $id );
ok( $time >= 270 && $time <= 330, "Defined offset, no offset type ($time)" );

# should implement guassian when req.


print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
