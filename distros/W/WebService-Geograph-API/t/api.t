# -*- perl -*-
# t/001_load.t - check module loading and create testing directory

use Test::More 'no_plan' ;

use WebService::Geograph::API ;

my $api = WebService::Geograph::API->new ({ 'key' => 'dummy_key' });
isa_ok ($api, 'WebService::Geograph::API' );

my $noapi = WebService::Geograph::API->new() ;
is ($noapi, undef, 'Did not create API without a key.') ;

my $rh_invalid_modes = {
	'non-existant'    => 'XXX',
	'not-defined' => undef 
} ;

foreach (keys %$rh_invalid_modes) {
	my $mode = $rh_invalid_modes->{$_} ;
	my $l = $api->lookup($mode, { } ) ;
	is ($l, undef, "$_ was not recognized as a valid mode.") ;
}

