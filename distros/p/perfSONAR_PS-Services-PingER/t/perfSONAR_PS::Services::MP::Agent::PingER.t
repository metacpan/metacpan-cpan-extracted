use Test::More 'no_plan';
use Log::Log4perl qw( :levels);

Log::Log4perl->easy_init($DEBUG);

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok('perfSONAR_PS::Services::MP::Agent::PingER');

# instantiate
my $agent = perfSONAR_PS::Services::MP::Agent::PingER->new();
ok( $agent->isa( 'perfSONAR_PS::Services::MP::Agent::Ping'), 'Instantiation');

# init agent
ok( $agent->init() eq 0, "init" );

# setup options
my $host = 'localhost';
$agent->destination( $host );
ok( $agent->destination() eq $host, 'setup destination');

my $hostIp = '127.0.0.1';
$agent->destinationIp( $hostIp );
ok( $agent->destinationIp() eq $hostIp, 'setup destination');


my $count = 5;
$agent->count( $count );
ok( $agent->count() eq $count, 'setup count');

my $packetSize = 1000;
$agent->packetSize( $packetSize );
ok( $agent->packetSize() == $packetSize, 'setup packetSize');

my $ttl = 64;
$agent->ttl( $ttl );
ok( $agent->ttl() == $ttl, 'setup ttl');

my $interval = 1;
$agent->interval( $interval );
ok( $agent->interval() == $interval, 'setup interval');

my $timeout = 10;
$agent->timeout( $timeout );
ok ($agent->timeout() == $timeout, 'setup timeout'); 

my $packetInterval = 1; 
$agent->packetInterval ( $packetInterval );
ok ($agent->packetInterval() == $packetInterval, 'setup packet interval');

# do the measurement
my $status = $agent->collectMeasurements();
ok( $status eq 0 , 'collectMeasurements()' );

# check commonTime object type for the results
use Data::Dumper;
print  Dumper $agent->results();
ok( $agent->results(), "Results okay" );

# output commontime as xml
#print $agent->results()->asString();

# create the message
ok( $agent->toDOM()->isa( XML::LibXML::Element ) eq 1, "toDOM: " . $agent->toDOM()->toString()  );



print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
