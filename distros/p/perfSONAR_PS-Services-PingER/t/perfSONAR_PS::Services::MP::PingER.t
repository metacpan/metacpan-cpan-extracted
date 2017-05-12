use Test::More 'no_plan';
use Log::Log4perl qw( :levels);

Log::Log4perl->easy_init($DEBUG);

my $tempDB = '/tmp/pingerMA.sqlite3';
my $config = {
	'PingERMP' => {
		'metadata_db_type' => 'SQLite',
		'metadata_db_name' => $tempDB,
		'metadata_db_user' => 'pinger',
		'metadata_db_pass' => 'pinger',
	}
};


print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok('perfSONAR_PS::Services::MP::PingER');
use_ok('perfSONAR_PS::Services::MP::Config::PingER');

# instantiate
my $mp = perfSONAR_PS::Services::MP::PingER->new( $config );
ok( $mp->isa( 'perfSONAR_PS::Services::MP::PingER'), 'Instantiation');

# create a schedule configuration (use pinger in this case)
my $conf = perfSONAR_PS::Services::MP::Config::PingER->new();
ok( $conf->isa( 'perfSONAR_PS::Services::MP::Config::PingER'), 'Config');

# load the schedule
my $config = 't/testfiles/pinger-landmarks.xml';
ok( $conf->load( $config ) eq 0, "loading $config" );

# assign schedule to scheduler
ok( $mp->addTestSchedule( $conf ) eq 0, "initiating schedule" );

use Data::Dumper;
print Dumper $mp->schedule();

# create a test
my $test = {
	'destinationIp' => '134.79.18.163',
	'destination'	=> 'www.slac.stanford.edu',
	'count'			=> 5,
	'packetSize'	=> 100,
	'ttl'			=> 128,
	'interval'		=> 1,	
};

# get an agent
my $agent = $mp->getAgent( $test );
ok( UNIVERSAL::can( $agent, 'isa' ) 
	&& $agent->isa( "perfSONAR_PS::Services::MP::Agent::PingER" ), "agent");

# run the agent
my $res = $agent->collectMeasurements();
ok( $res eq 0, "agent collection");

# setup database

# create a blank database using sqlite for now
# configs
`rm $tempDB; sqlite3 $tempDB < MA/PingER/create_pingerMA_SQLite.sql`; 
ok( -e $tempDB, "create temporary database $tempDB" );

# have to initate the db
$res = $mp->setupDatabase();
ok( $res eq 0, "setting up database");

# store teh data
$res = $mp->storeData( $agent, 'id' );
ok( $res eq 0, "store into database" );

`rm $tempDB`;

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
