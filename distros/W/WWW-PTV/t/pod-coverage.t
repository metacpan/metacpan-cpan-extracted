use strict;
use warnings;
use Test::More;

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

pod_coverage_ok( 'WWW::PTV' );
pod_coverage_ok( 'WWW::PTV::Area', 		 { also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PTV::Route', 		 { also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PTV::Stop', 		 { also_private => [ 'new', 'routes' ] } );
pod_coverage_ok( 'WWW::PTV::TimeTable', 	 { also_private => [ 'new' ] } );
pod_coverage_ok( 'WWW::PTV::TimeTable::Schedule',{ also_private => [ 'new' ] } );
done_testing();
