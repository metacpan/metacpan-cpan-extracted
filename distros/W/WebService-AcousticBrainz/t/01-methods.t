#!perl
use Test::More;
use Test::Exception;

use Mojo::Base -strict;
use Mojolicious;

use_ok 'WebService::AcousticBrainz';

my $ws = new_ok 'WebService::AcousticBrainz';

throws_ok { $ws->fetch }
    qr/No mbid provided/, 'fetch with no mbid';

throws_ok { $ws->fetch( mbid => 1234 ) }
    qr/No endpoint provided/, 'fetch with no endpoint';

my $mock = Mojolicious->new;
$mock->log->level('fatal'); # only log fatal errors to keep the server quiet
$mock->routes->get('/api/v1/1234567890/low-level' => sub {
        my $c = shift;
        is $c->param('n'), 2, 'n param';
        return $c->render( status => 200, json => { ok => 1 } );
    }
);
$ws->ua->server->app($mock); # point our UserAgent to our new mock server

$ws->base('');

my $got;
lives_ok {
    $got = $ws->fetch(
        mbid     => '1234567890',
        endpoint => 'low-level',
        query    => { n => 2 },
    );
} 'fetch lives';
is_deeply $got, { ok => 1 }, 'fetch';

done_testing();
