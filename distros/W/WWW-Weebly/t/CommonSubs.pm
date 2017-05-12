package CommonSubs;

sub initiate_api {

	require WWW::Weebly;

	my $api = WWW::Weebly->new(
		{
			tid_seed      => 'brandname',
			weebly_secret => $ENV{'WEEBLY_SECRET'} || 'mysecretkey',
			weebly_url    => $ENV{'WEEBLY_URL'}    || 'http://testing-weebly.not.real.com',
			http_opts     => { 'agent' => 'WWW-Weebly', 'timeout' => 20, 'verify_SSL' => 'false', 'SSL_options' => {'SSL_verify_mode' => '0x00'} },
		}
	);

	return $api;
}

1;