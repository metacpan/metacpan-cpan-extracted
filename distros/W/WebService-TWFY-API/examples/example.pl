#!/usr/bin/perl 

use warnings ;
use strict ;

use WebService::TWFY::API ;

## This key will not work, get you own at 
## http://www.theyworkforyou.com/api/key

my $rh = { key => 'abc1234' }; 

my $api = WebService::TWFY::API->new( $rh );

my $rv = $api->query ( 'getConstituency', { 'postcode' => 'W128JL',
                                            'output'   => 'xml',
                                           } ) ;

if ($rv->{is_success}) {
  my $results = $rv->{results} ;
  print "$results \n" ;
}