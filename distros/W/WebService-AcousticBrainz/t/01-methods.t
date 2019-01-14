#!perl
use Test::More;

use Mojo::Base -strict;
use Mojolicious;

use Try::Tiny qw(try catch);

use_ok 'WebService::AcousticBrainz';

my $ws = WebService::AcousticBrainz->new;
isa_ok $ws, 'WebService::AcousticBrainz';

my $mock = Mojolicious->new;
$mock->log->level('fatal'); # only log fatal errors to keep the server quiet
$mock->routes->get('/1234567890/low-level' => sub {
    my $c = shift;
    my $n = $c->param('n');
    return $c->render(status => 200, json => {ok => 1}) if $n eq 2;
    return $c->render(status => 400, text => 'Missing values');
});
$ws->ua->server->app($mock); # point our UserAgent to our new mock server

$ws->base(Mojo::URL->new(''));

can_ok($ws, 'fetch');

my $data = try { $ws->fetch( mbid => '1234567890', endpoint => 'low-level', query => { n => 2 } ) } catch { $_ };
is_deeply $data, {ok => 1}, 'fetch';

done_testing();
