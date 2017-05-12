use Test::More 'no_plan';
use Log::Log4perl qw( :levels);

Log::Log4perl->easy_init($DEBUG);

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok('perfSONAR_PS::Services::MP::Scheduler');
use_ok('perfSONAR_PS::Services::MP::Config::PingER');

# instantiate
my $scheduler = perfSONAR_PS::Services::MP::Scheduler->new();
ok( $scheduler->isa( 'perfSONAR_PS::Services::MP::Scheduler'), 'Instantiation');

# create a schedule configuration (use pinger in this case)
my $conf = perfSONAR_PS::Services::MP::Config::PingER->new();
ok( $conf->isa( 'perfSONAR_PS::Services::MP::Config::PingER'), 'Config');

# load the schedule
my $config = 't/testfiles/pinger-landmarks.xml';
ok( $conf->load( $config ) eq 0, "loading $config" );

# assign schedule to scheduler
ok( $scheduler->addTestSchedule( $conf ) eq 0, "initiating schedule" );

use Data::Dumper;
print Dumper $scheduler->schedule();

# how should we test forking?
#$scheduler->run();



print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
