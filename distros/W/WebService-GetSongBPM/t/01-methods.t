#!perl
use Test::More;
use Test::Exception;

# Mocking example taken from:
# http://blogs.perl.org/users/chase_whitener/2016/01/mock-testing-web-services-with-mojo.html

use Mojo::Base -strict;
use Mojolicious;

use Try::Tiny qw(try catch);

use_ok 'WebService::GetSongBPM';

throws_ok { WebService::GetSongBPM->new }
    qr/Missing required arguments: api_key/, 'api_key required';

my $ws = new_ok 'WebService::GetSongBPM' => [ api_key => '1234567890' ];

throws_ok { $ws->fetch }
    qr/Can't fetch: No type set/, 'no type set';

$ws = new_ok 'WebService::GetSongBPM' => [
    api_key => '1234567890',
    artist  => 'van halen',
    song    => 'jump',
];

my $mock = Mojolicious->new;
$mock->log->level('fatal'); # only log fatal errors to keep the server quiet
$mock->routes->get('/search' => sub {
    my $c = shift;
    is $c->param('api_key'), '1234567890', 'api_key param';
    is $c->param('type'), 'both', 'type param';
    is $c->param('lookup'), 'song:jump+artist:van halen', 'lookup param';
    return $c->render(status => 200, json => { ok => 1 });
});
$ws->ua->server->app($mock); # point our UserAgent to our new mock server

$ws->base('');

lives_ok { $ws->fetch } 'fetch lives';

done_testing();
