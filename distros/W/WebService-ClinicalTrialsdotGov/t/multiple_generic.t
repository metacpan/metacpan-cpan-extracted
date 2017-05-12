
use strict;
use warnings;

use Test::More tests => 15;

use_ok('WebService::ClinicalTrialsdotGov');

my $rh_params = {
   'term'  => 'cancer',
   'start' => 0,
   'count' => 10,
   'mode'  => 'search',   
};

my $CT = 
   WebService::ClinicalTrialsdotGov->new( $rh_params );

isa_ok( $CT, 'WebService::ClinicalTrialsdotGov');

my $Results = $CT->results;

isa_ok( $Results, 'WebService::ClinicalTrialsdotGov::Reply' );

my $ra_all_obj = 
   $Results->get_search_results;
   
ok( $ra_all_obj, 'get_all_studies_obj' );

is( scalar(@$ra_all_obj), 10, 'get_all_studies_obj' );

foreach my $so ( @$ra_all_obj ) {
   isa_ok( $so, 'WebService::ClinicalTrialsdotGov::SearchResult' );
}

