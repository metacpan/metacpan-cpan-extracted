#!perl -T

use lib 't/lib';

use Test::More tests => 4;

use Test::Override::UserAgent for => 'testing';

# Create a configuration
my $conf = Test::Override::UserAgent->new->override_request(
	host => 'localhost',
	path => '/bad',
	sub { return 600; },
)->override_request(
	host => 'localhost',
	path => '/bad_hash.psgi',
	sub { return {status => 200}; },
);

# Create the UA
my $ua = $conf->install_in_user_agent(LWP::UserAgent->new);

{
	# Get the bad return response
	my $response = $ua->get('http://localhost/bad');

	like $response->content, qr{: 600}ms,
		'Content body contains the return from handler (scalar)';
	like $response->status_line, qr{invalid}ms,
		'Status line contains invalid (scalar)';
}

{
	# Get the bad return response
	my $response = $ua->get('http://localhost/bad_hash.psgi');

	like $response->content, qr{HASH}ms,
		'Content body contains the return from handler (hash)';
	like $response->status_line, qr{invalid}ms,
		'Status line contains invalid (hash)';
}
