use Test::More 'no_plan';
use Log::Log4perl qw( :levels);

Log::Log4perl->easy_init($DEBUG);

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok('perfSONAR_PS::Services::MP::Agent::CommandLine');

# instantiate
my $cmd = '/bin/ping -c %count% %destination%';
my %options = ( 'count' => 5, 'destination' => 'localhost' );

my $agent = perfSONAR_PS::Services::MP::Agent::CommandLine->new( $cmd, \%options );
ok( $agent->isa( 'perfSONAR_PS::Services::MP::Agent::CommandLine'), 'Instantiation');

# set timeout
ok ($agent->timeout( 60 ) == 60, "Set timeout");
# find cmd
ok( $agent->command() eq $cmd, "Command okay");

# options
my $optionsError = 0;
while( my ($k,$v) = each %{$agent->options()} ) {
	$optionsError++
		unless ( exists $options{$k} && $v eq $options{$k} );
}
ok( $optionsError eq 0, 'Options okay' );


# init
ok( $agent->init() eq 0, "initialisation okay");


# run the command
my $commandString = $cmd;
while( my ($k,$v) = each %options ) {
		$commandString =~ s/\%$k\%/$v/g;
}
my $status = $agent->collectMeasurements();
ok( $agent->commandString() eq  $commandString, "Command string ok");
ok( $status eq 0 , 'collectMeasurements()' );

# timeouts

$agent->timeout( 3 );
$status = $agent->collectMeasurements();
ok( $status eq -1, 'collectMeasurement() timeout');

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
