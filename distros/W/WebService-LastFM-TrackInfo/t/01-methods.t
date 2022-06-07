#!perl
use Test::More;
use Test::Exception;

use Mojo::Base -strict;
use Mojolicious;

subtest 'throws' => sub {
    use_ok 'WebService::LastFM::TrackInfo';

    throws_ok { WebService::LastFM::TrackInfo->new }
        qr/Missing required arguments: api_key/, 'api_key required';

    my $ws = new_ok 'WebService::LastFM::TrackInfo' => [ api_key => 'abc123' ];

    throws_ok { $ws->fetch }
        qr/No artist provided/, 'fetch with no artist';

    throws_ok { $ws->fetch(artist => 'foo') }
        qr/No track provided/, 'fetch with no track';

    $ws = new_ok 'WebService::LastFM::TrackInfo' => [
        api_key => 'abc123',
        method  => 'album',
    ];

    throws_ok { $ws->fetch(artist => 'foo') }
        qr/No album provided/, 'fetch with no album';
};

subtest 'mock' => sub {
    my $ws = new_ok 'WebService::LastFM::TrackInfo' => [ api_key => 'abc123' ];

    my $mock = Mojolicious->new;
    $mock->log->level('fatal'); # only log fatal errors to keep the server quiet
    $mock->routes->get('/2.0' => sub {
            my $c = shift;
            is $c->param('api_key'), 'abc123', 'api_key';
            is $c->param('artist'), 'foo', 'artist';
            is $c->param('track'), 'bar', 'track';
            is $c->param('format'), 'json', 'format';
            is $c->param('method'), 'track.getInfo', 'method';
            return $c->render( status => 200, json => { ok => 1 } );
        }
    );
    $ws->ua->server->app($mock); # point our UserAgent to our new mock server

    $ws->base('');

    my $got;
    lives_ok {
        $got = $ws->fetch(
            artist => 'foo',
            track  => 'bar',
        );
    } 'fetch lives';
    is_deeply $got, { ok => 1 }, 'fetch';
};

done_testing();
