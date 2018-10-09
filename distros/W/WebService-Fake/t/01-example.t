use strict;
use Test::More;
use Test::Mojo;
use Mojo::JSON;
use Path::Tiny;

my $true = Mojo::JSON::true();

$ENV{WEBSERVICE_FAKE} =
  path(__FILE__)->parent(2)->child(qw< eg webservice-fake.yml >);
my $t = Test::Mojo->new('WebService::Fake');

# plain get to /
$t->get_ok('/')->status_is(200)->content_type_is('application/json')
  ->header_is(Server => 'My::Server')->header_is('X-Whatever' => 'hello')
  ->header_like('X-Hey' => qr{(?mxs:\AYou .* rock\z)})
  ->json_is({status => $true, data => {message => 'ciao '}});

# get to / with a name parameter
$t->get_ok('/?name=polettix')->status_is(200)
  ->content_type_is('application/json')->header_is(Server => 'My::Server')
  ->header_is('X-Whatever' => 'hello')
  ->header_like('X-Hey' => qr{(?mxs:\AYou .* rock\z)})
  ->json_is({status => $true, data => {message => 'ciao polettix'}});

# get to /simple, has custom wrapper
$t->get_ok('/simple')->status_is(200)->content_type_is('text/plain')
  ->header_is('X-Whatever' => 'hello')
  ->header_like('X-Hey' => qr{(?mxs:\AYou .* rock\z)})
  ->content_is("I say: hullo\n");

# disable body_wrapper
$t->get_ok('/nowrap')->status_is(200)->content_type_is('text/plain')
  ->content_is("LOOK MA', NO WRAP!\n");

# get stuff from other part of YAML
$t->get_ok('/somestuff')->status_is(200)
  ->json_is({status => $true, data => {hey => 'joe'}});

$t->post_ok('/add')->status_is(201)->content_is("ok\n");

$t->get_ok('/visit-config')->status_is(200)
  ->json_like('/data/0' => qr{(?mxs:\Aone\z)})
  ->json_like('/data/3' => qr{(?mxs:\A\d+\z)});

$t->get_ok('/whatnow')->status_is(200)->content_is('starter');
$t->post_ok('/prepare/0')->status_is(204)->content_is('');
$t->get_ok('/whatnow')->status_is(200)->content_is('one');
$t->post_ok('/prepare/3')->status_is(204)->content_is('');
$t->get_ok('/whatnow')->status_is(200)->content_like(qr{(?mxs:\A\d+\z)});

done_testing();
