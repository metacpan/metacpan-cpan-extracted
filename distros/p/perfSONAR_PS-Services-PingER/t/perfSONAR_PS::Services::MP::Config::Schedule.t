use Test::More 'no_plan';
use Log::Log4perl qw( :levels);

Log::Log4perl->easy_init($DEBUG);

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok('perfSONAR_PS::Services::MP::Config::Schedule');

# instantiate
my $schedule = perfSONAR_PS::Services::MP::Config::Schedule->new();
ok( $schedule->isa( 'perfSONAR_PS::Services::MP::Config::Schedule'), 'Instantiation');

# artififically insert some values
my $sched = {
	'test1' => { 
					'param1' => 'value1',
					'param2' => 'value2',
	 			},
	'test2' => { 
					'param1' => 'value1',
					'param2' => 'value2',
					'measurementPeriod' => '10',
	 			},
	'test3' => {
					'param1' => 'value1',
					'param2' => 'value2',
					'measurementPeriod' => '30',
					'measurementOffset' => '10',
				},
};
$schedule->config( $sched );

# get a list of the test ids (the keys)
my %seen = ();
foreach my $t ( $schedule->getAllTestIds() ){
	$seen{$t}++;
}
foreach my $k ( keys %{$sched} ) {
	$seen{$k}++;
}
# each seen should be twice
my $okay = 0;
foreach my $s ( keys %seen ) {
	$okay++
		if $seen{$s} == 2;
}
ok( $okay eq scalar keys %{$sched}, "Test id list" );

# check for first test; would return undef as no period is defined
ok( ! $schedule->getTestNextTimeFromNowById( 'test1' ), "No defined period" );

# test 2 should have just 10; as no offset is defined
ok( $schedule->getTestNextTimeFromNowById( 'test2' ) eq 10, "No defined offset" );

# test 3 should return a value between 20 to 40 (30+/-10);
my $time = $schedule->getTestNextTimeFromNowById( 'test3' );
ok( $time >= 20 && $time <= 40, "Defined offset, no offset type ($time)" );

# should implement guassian when req.


print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
