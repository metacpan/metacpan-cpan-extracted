#!perl
use Test::More;

use Mojo::Base -strict;
use Mojolicious;

use Try::Tiny qw(try catch);

use_ok 'WebService::Hooktheory';

my $ws = new_ok 'WebService::Hooktheory';

my $result = try { $ws->fetch } catch { $_ };
like $result, qr/No activkey provided/, 'activkey required';

$ws = WebService::Hooktheory->new( activkey => '1234567890' );
isa_ok $ws, 'WebService::Hooktheory';

$result = try { $ws->fetch } catch { $_ };
like $result, qr/No endpoint provided/, 'endpoint required';

my $mock = Mojolicious->new;
$mock->log->level('fatal'); # only log fatal errors to keep the server quiet
$mock->routes->get('/trends/nodes' => sub {
    my $c = shift;
    my $p = $c->param('cp');
    return $c->render(status => 200, json => {ok => 1}) if $p eq '4,1';
    return $c->render(status => 400, text => 'Missing values');
});
$ws->ua->server->app($mock); # point our UserAgent to our new mock server

$ws->base(Mojo::URL->new(''));

can_ok $ws, 'fetch';

my $data = try {
    $ws->fetch(
        endpoint => '/trends/nodes',
        query    => { cp => '4,1' }
    )
} catch { $_ };
is_deeply $data, {ok => 1}, 'fetch';

done_testing();
