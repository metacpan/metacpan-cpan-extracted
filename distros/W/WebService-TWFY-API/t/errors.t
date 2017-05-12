# -*- perl -*-

use Test::More;

eval "use Test::Exception";
plan skip_all => "Test::Exception required for testing pod coverage" if $@;

use Test::Exception ('no_plan') ;

BEGIN { use_ok( 'WebService::TWFY::API' ); }

my $rh = { key => 'ABC123' };
my $api = WebService::TWFY::API->new( $rh );

dies_ok { my $rv = $api->query ( 'fake_function', {   'postcode' => 'W12',
                                            'output'   => 'xml' ,
                                           } ) ;

                                         } 'fake function dies okay' ;

dies_ok { my $rv = $api->query ( 'getLord', {   'postcode' => 'W12',
                                            'output'   => 'FAKE' ,
                                        } ) ;
                                      
                                      } 'fake output dies okay' ;