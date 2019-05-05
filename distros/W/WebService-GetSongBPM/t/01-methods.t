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

my $ws = WebService::GetSongBPM->new(api_key => '1234567890');
isa_ok $ws, 'WebService::GetSongBPM';

my $data = try { $ws->fetch } catch { $_; };
like $data, qr/Can't fetch: No type set/, 'no type set';

$ws = WebService::GetSongBPM->new(
    api_key => '1234567890',
    artist  => 'van halen',
    song    => 'jump',
);
isa_ok $ws, 'WebService::GetSongBPM';

my $mock = Mojolicious->new;
$mock->log->level('fatal'); # only log fatal errors to keep the server quiet
$mock->routes->get('/search' => sub {
    my $c = shift;
    my $key = $c->param('api_key');
    my $type = $c->param('type');
    my $lookup = $c->param('lookup');
    return $c->render(status => 200, json => {ok => 1}) if $key && $type && $lookup;
    return $c->render(status => 400, text => 'Missing values');
});
$ws->ua->server->app($mock); # point our UserAgent to our new mock server

$ws->base(Mojo::URL->new(''));

can_ok $ws, 'fetch';

$data = try { $ws->fetch } catch { $_; };
is_deeply $data, {ok => 1}, 'fetch';

done_testing();
