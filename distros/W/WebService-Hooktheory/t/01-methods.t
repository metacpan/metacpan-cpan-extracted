#!perl
use Test::More;
use Test::Exception;

use Mojo::Base -strict;
use Mojolicious;

use_ok 'WebService::Hooktheory';

my $ws = new_ok 'WebService::Hooktheory';
throws_ok { $ws->fetch }
    qr/No activkey provided/, 'activkey required';

$ws = new_ok 'WebService::Hooktheory' => [ activkey => '1234567890' ];

throws_ok { $ws->fetch }
    qr/No endpoint provided/, 'endpoint required';

throws_ok { $ws->fetch(endpoint => 'foo') }
    qr/No query provided/, 'query required';

my $mock = Mojolicious->new;
$mock->log->level('fatal'); # only log fatal errors to keep the server quiet
$mock->routes->get('/v1/trends/nodes' => sub {
    my $c = shift;
    is $c->param('cp'), '4,1', 'cp param';
    return $c->render(status => 200, json => { ok => 1 });
});
$ws->ua->server->app($mock); # point our UserAgent to our new mock server

$ws->base('');

lives_ok {
    $ws->fetch(
        endpoint => '/trends/nodes',
        query    => { cp => '4,1' }
    )
} 'fetch lives';

done_testing();
