#!perl -T

use lib 't/lib';

use Test::More tests => 5;

use LWP::UserAgent;
use MyUAConfig; # Our configuration

# Create a new user agent
my $ua = LWP::UserAgent->new;

# Install the overrides
MyUAConfig->configuration->install_in_user_agent($ua);

{
	# Filehandle
	my $response = $ua->get('http://localhost/fh.psgi');

	# See if the response body is right
	is $response->content, "some\nwords\n",
		'PSGI filehandle content';
}

{
	# Headers
	my $response = $ua->get('http://localhost/headers.psgi');

	is scalar($response->header('X-PSGI-Test')), 'header, header2',
		'PSGI header order';

	is_deeply [$response->header('X-PSGI-Test')], [qw(header header2)],
		'PSGI header multi';
}

{
	# Status
	is $ua->get('http://localhost/status.psgi?200')->code, 200,
		'Code returned 200';
	is $ua->get('http://localhost/status.psgi?404')->code, 404,
		'Code returned 404';
}
