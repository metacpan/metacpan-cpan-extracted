use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::Protocol::PSGI';

use Ukigumo::Client;
use Ukigumo::Client::VC::Git;
use Ukigumo::Client::Executor::Perl;
use Ukigumo::Constants;
use JSON;

LWP::Protocol::PSGI->register(sub{
	ok 1;

	[200, ['Content-Type' => 'text/json'], [
		encode_json(+{
			report => {
				url => 'http://...',
			},
		})
	]];
});

my $client = Ukigumo::Client->new(
    vc => Ukigumo::Client::VC::Git->new(
        branch     => 'success',
        repository => 'https://github.com/tokuhirom/Acme-Failing.git',
    ),
    server_url => 'http://localhost/',
    executor   => Ukigumo::Client::Executor::Perl->new(),
    quiet => 0,
);
$client->run();

done_testing;

