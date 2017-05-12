use strict;
use warnings;
use Test::More;

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
if ( $@ ) {
	plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
}
else {
	plan tests => 16
}

pod_coverage_ok( 'WWW::PIDS' );
pod_coverage_ok( 'WWW::PIDS::CoreDataChanges',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::Destination',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::ListedStop',		{ also_private => [ 'new', 'TurnMessage', 'TurnType' ] } );
pod_coverage_ok( 'WWW::PIDS::NextPredictedStopDetail',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::PredictedTime',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::PredictedArrivalTimeData',	{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::RouteChange',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::RouteDestination',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::RouteNo',			{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::RouteStop',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::RouteSummary',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::ScheduledTime',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::StopChange',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::StopInformation',		{ also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PIDS::TripSchedule',		{ also_private => [ 'new' ] } );


