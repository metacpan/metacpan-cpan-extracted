
use v5.38;
use Test::More;
use WebService::Akeneo::Transport;
use WebService::Akeneo::Config;
use Mojo::UserAgent;
use Mojo::Message::Response;
use Mojo::Transaction::HTTP;

{ package DummyAuth; use v5.38; sub new { bless {}, shift } sub refresh_if_needed { 1 } sub bearer { 'X' } }

my $transport = WebService::Akeneo::Transport->new(
  config => WebService::Akeneo::Config->new(
    base_url      => 'https://example.test',
    client_id     => 'id',
    client_secret => 'sec',
    username      => 'u',
    password      => 'p',
  ),
  auth => DummyAuth->new,
);

my $sent;
$transport->on_request(sub { my ($i)=@_; $sent = $i->{body} });

my $ua = Mojo::UserAgent->new;
no warnings 'redefine';
*Mojo::UserAgent::start = sub ($self, $tx) {
  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_type('application/json');
  $res->body('{}');
  $tx->res($res);
  return $tx;
};
use warnings;

$transport->set_ua($ua);

my $records = [
  { code => 'mixers' },
  { code => 'turntables' },
];

my $out = $transport->request('PATCH','/categories', ndjson => $records);
ok(defined $sent && length $sent, 'NDJSON body sent');
is(index($sent,'['), -1, 'NDJSON has no opening bracket');
is(index($sent,']'), -1, 'NDJSON has no closing bracket');

my @lines = grep { length } split /\r?\n/, $sent;
is scalar(@lines), 2, 'one line per object';

pass('request returned (decoded JSON for stub)');
done_testing;
