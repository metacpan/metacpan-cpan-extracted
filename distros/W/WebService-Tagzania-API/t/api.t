# -*- perl -*-
# t/api.t - some basic api testing

use Test::Exception ('no_plan') ;
use Test::More ;

use WebService::Tagzania::API ;

my $api = WebService::Tagzania::API->new() ;
isa_ok ( $api, 'WebService::Tagzania::API') ;

my $rh_params = {
  start  => 0,
  number => 1,
  minlng => -9.25,
  maxlng => 4.55,
  maxlat => 43.80,
} ;

dies_ok { 
          my $results = $api->query( $rh_params ) ;
        } ' missing parameter ' ;

