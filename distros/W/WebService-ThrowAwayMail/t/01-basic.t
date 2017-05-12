use Test::More;

use WebService::ThrowAwayMail;

use Test::MockObject;

(my $tiny = Test::MockObject->new)->mock('get', sub { return { content => 'meh', success => 1 } });

my $client = WebService::ThrowAwayMail->new(
    tiny => $tiny,
);

my $alias = $client->get_alias();

is $alias, 'meh', 'okay a simple test';

(my $dead = Test::MockObject->new)->mock('get', sub { return  {
	'reason' => 'Not Found',
	 'headers' => {
					 'vary' => 'Accept-Encoding',
					 'server' => 'nginx/1.10.0 (Ubuntu)',
					 'connection' => 'keep-alive',
					 'date' => 'Mon, 13 Mar 2017 15:49:56 GMT',
					 'content-length' => '178',
					 'content-type' => 'text/html'
			   },
	'protocol' => 'HTTP/1.1',
	'status' => '404',
};});

my $dead_client = WebService::ThrowAwayMail->new(
    tiny => $dead,
);

eval { $dead_client->get_alias(); };
my $death = $@;
like($death, qr/^something went terribly wrong/, "caught the carp");

eval { $client->get_alias('nothing allowed') };
my $no_params = $@;
like($no_params, qr/Error - Invalid count in params for sub - get_alias - expected - 0 - got - 1/, "no params allowed");

(my $tiny_url = Test::MockObject->new)->mock('get', sub { return { url => $_[1], content => 'meh', success => 1 } });

my $get_client = WebService::ThrowAwayMail->new(
    tiny => $tiny_url,
);

is($get_client->get('another_url')->{url}, 'another_url', 'expected url blah');

done_testing();

1;
