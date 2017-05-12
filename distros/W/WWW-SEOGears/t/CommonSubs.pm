package CommonSubs;

use WWW::SEOGears;

sub initiate_api {

	my $api = WWW::SEOGears->new( { brandname => $ENV{'SEOGEARS_BRANDNAME'} || 'mybrandname',
	                                brandkey  => $ENV{'SEOGEARS_BRANDKEY'}  || 'mybrandkey',
	                                sandbox   => '1',
	                                http_opts => { 'agent' => 'WWW-SEOGears', 'timeout' => 20, 'verify_SSL' => 0, 'SSL_options' => {'SSL_verify_mode' => 0x00} }
	                              } );

	return $api;
}

sub newuser {

	my $api        = shift;
	my $params     = shift;
	my $param_test = shift;

	if ($param_test) {
		delete $params->{'price'};
	}
	my $output = eval { $api->newuser($params); };
	return $output;
}

sub random_uid {

	my $limit    = 12;
	my $possible = 'abcdefghijkmnpqrstuvwxyz0123456789';
 	my $string   = '';
 	while (length($string) < $limit) {
 		$string .= substr( $possible, ( int( rand( length($possible) ) ) ), 1 );
 	}
 	return $string;
}

sub gen_rand_params {

	my $params = {};
	$params->{'userid'}    = random_uid();
	$params->{'name'}      = 'testing';
	$params->{'email'}     = random_uid().'@hostgatortesting.com';
	$params->{'phone'}     = '1.5552223333';
	$params->{'domain'}    = 'testing-'.random_uid().'-testing.com';
	$params->{'rep'}       = 'testing@testing.com';
	$params->{'placement'} = 'reg';
	$params->{'pack'}      = '32';
	$params->{'price'}     = '14.99';
	$params->{'months'}    = 1;
	return $params;
}

1;
