package MyUAConfig;

use IO::String;
use Test::Override::UserAgent for => 'configuration';

# Disallow live requests
allow_live(0);

# Simple URI echo
override_request
	scheme => 'http',
	host   => 'localhost',
	path   => '/echo_uri',
	sub { return [200, ['Content-Type' => 'text/plain'], [shift->uri]]; };

# PSGI filehandle
override_request
	host => 'localhost',
	path => '/fh.psgi',
	sub {
		return [200, ['Content-Type' => 'text/plain'], IO::String->new("some\nwords\n")];
	};

# PSGI headers
override_request
	host => 'localhost',
	path => '/headers.psgi',
	sub {
		my @headers = (
			'Content-Type' => 'text/plain',
			'X-PSGI-Test'  => 'header',
			'X-PSGI-Test'  => 'header2',
			'Vary'         => 'something',
		);

		return [200, \@headers, []];
	};

# PSGI status
override_request
	host => 'localhost',
	path => '/status.psgi',
	sub {
		return [shift->uri->query, ['Content-Type' => 'text/plain'], []];
	};

1;
