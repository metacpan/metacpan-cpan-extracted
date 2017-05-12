#!/usr/bin/perl -w

use strict ;

use WebService::Tagzania::API ;
use Data::Dumper ;
use XML::Simple ;

my $api = new WebService::Tagzania::API ;

my $rh_params = {
  'start'  => 0,
  'number' => 10,
  'minlng' => 23.1,
  'minlat' => 37.1,
  'maxlng' => 23.9,
  'maxlat' => 37.9,
} ;

my $response = $api->query( $rh_params ) ;
my $content = $response->{_content} ;

my $ref = XMLin( $content , KeepRoot => 1, KeyAttr => 'marker' );
my $trunk = $ref->{xml} ;
my $data = $trunk->{markers} ;
my $rhah = $data->{marker} ;

print Dumper($rhah) ;