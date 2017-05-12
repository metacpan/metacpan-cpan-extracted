
use strict;
use warnings;

use Test::More tests => 6;
use Data::Dumper;

use_ok('WebService::ClinicalTrialsdotGov');

my $rh_params = {
   'id'    => 'NCT00622401',
   'mode'  => 'show',   
};

my $CT = 
   WebService::ClinicalTrialsdotGov->new( $rh_params );

isa_ok( $CT, 'WebService::ClinicalTrialsdotGov');

my $Results = $CT->results;

isa_ok( $Results, 'WebService::ClinicalTrialsdotGov::Reply' );

my $Study = 
   $Results->get_study;

ok ( $Study, 'get_study' );

isa_ok( $Study, 'WebService::ClinicalTrialsdotGov::Study' );

is( $Study->{id_info}->{nct_id}, 'NCT00622401' );

