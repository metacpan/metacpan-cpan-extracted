## Please see file perltidy.ERR
use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;
use Sub::Override;
use Test::Mock::One;

use OpenAPI::Client qw();
use Types::Serialiser qw();
use Mojo::Transaction::HTTP;

use WebService::Xential;

my $xential = WebService::Xential->new(
    api_key => 'foo',
    api_host => '127.0.0.1',
);

my $args;
my $override = Sub::Override->new(
  'OpenAPI::Client::WebService__Xential_xential_json::op_auth_whoami' => sub {
    my $client = shift;
    $args = shift;
    return Test::Mock::One->new(
      'X-Mock-Strict' => 1,
      error           => undef,
      res             => { json => \{ 'foo' => 'bar', } },
    );
  }
);

my $whoami = $xential->whoami();
cmp_deeply($whoami, { foo => 'bar' }, "Got the whoami result");

# The session ID is stored in the client on_start, we need to parse the CODE,
# but we need to go deep into mojo for this. Let's not.
my $operation;
$override->override(
  'WebService::Xential::api_call' => sub {
    my $client = shift;
    $operation = shift;
    $args = shift;
    return { 'foo' => 'bar' }
  }
);
$whoami = $xential->whoami('session_id');
cmp_deeply($whoami, { foo => 'bar' }, "Got answer from whoami with session_id");
is($operation, 'op_auth_whoami', "... with the correct operation",);
cmp_deeply($args, { 'XSessionID', 'session_id'}, "... and seen the XSessionID");


my $client = $xential->client;

# Local testing, disable
#$client->base_url->port(9001);
#$client->base_url->scheme("http");
#my $res = $xential->create_ticket('<xml>here</xml>', { options => 'here' }, 'sessionid');
#diag explain $res;

# Here we test the local transactor from Mojo. This allows you to insert custom
# requests into Mojo and this is used for create_ticket
my $req = WebService::Xential::create_ticket_data(
    $client,
    Mojo::Transaction::HTTP->new(),
    {
        xml => '<xml>here</xml>',
        options => { foo => 'bar' },
    }
);

isa_ok($req, 'Mojo::Message::Request');
is($req->headers->content_type, 'multipart/form-data', "Correct content-type");

my $params = $req->params;
is($params->param('options'), '{"foo":"bar"}', "We have our options");

my $parts = $req->uploads;
is(@$parts, 1, "we have one upload");
is($parts->[0]->name, "ticketData", "... and the name is ticketData");
is($parts->[0]->filename, "ticketData.xml", "... and the correct filename");
is($parts->[0]->slurp, "<xml>here</xml>", "... and the correct content");

my $url = 'https://foo.example.com';
my $uuid = '1234';
$xential->start_document($url, $uuid, 'session_id');
is($operation, 'op_document_startDocument', "... with the correct operation",);
cmp_deeply($args, { 'XSessionID', 'session_id', ticketUuid => '1234', xmldataurl => $url}, "... and seen the correct arguments");

$xential->build_document(1, $uuid, 'session_id');
is($operation, 'op_document_buildDocument', "Build document with the correct operation",);
cmp_deeply(
  $args,
  { 'XSessionID', 'session_id', documentUuid => '1234', close => $Types::Serialiser::true },
  "... and seen the correct arguments"
);

$xential->build_document(0, $uuid, 'session_id');
cmp_deeply(
  $args,
  { 'XSessionID', 'session_id', documentUuid => '1234', close => $Types::Serialiser::false },
  "... and with close = false"
);


done_testing;
